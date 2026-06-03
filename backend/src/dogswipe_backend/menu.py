from __future__ import annotations

import ipaddress
import re
import socket
from collections.abc import Callable, Iterable
from dataclasses import dataclass
from html.parser import HTMLParser
from typing import Protocol
from urllib.parse import urljoin, urlparse

import httpx

MAX_MENU_BYTES = 100_000
MAX_MENU_EXCERPT_CHARS = 500
MAX_MENU_HIGHLIGHTS = 4
MAX_MENU_REDIRECTS = 3
_BLOCKED_HOSTS = {
    "0",
    "localhost",
    "metadata.google.internal",
}
_BLOCKED_HOST_SUFFIXES = (
    ".home.arpa",
    ".internal",
    ".local",
    ".localhost",
)
_PRICE_PATTERN = re.compile(r"(?<!\w)\$\s?\d+(?:\.\d{1,2})?")
_MENU_HIGHLIGHT_RULES: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("Classic", ("classic", "snap dog", "cart dog")),
    ("Chili", ("chili", "coney")),
    ("Cheese", ("cheese", "cheddar")),
    ("Kimchi", ("kimchi",)),
    ("Spicy", ("spicy", "gochujang", "jalapeno", "hot sauce")),
    ("Mustard", ("mustard",)),
    ("Relish", ("relish",)),
    ("Onion", ("onion",)),
    ("Celery salt", ("celery salt",)),
    ("Bacon", ("bacon",)),
    ("All-beef", ("all-beef", "all beef", "beef frank")),
    ("Vegan", ("vegan", "plant-based", "plant based")),
)
HostResolver = Callable[[str, int | None], Iterable[str]]


@dataclass(frozen=True)
class MenuIngestionResult:
    status: str
    excerpt: str | None = None


@dataclass(frozen=True)
class _FetchedMenuResponse:
    content: bytes
    content_type: str
    encoding: str | None


class MenuIngestor(Protocol):
    async def ingest(self, url: str) -> MenuIngestionResult:
        raise NotImplementedError


class HTTPMenuIngestor:
    def __init__(
        self,
        *,
        timeout_seconds: float = 5.0,
        transport: httpx.AsyncBaseTransport | None = None,
        host_resolver: HostResolver | None = None,
    ) -> None:
        self.timeout_seconds = timeout_seconds
        self.transport = transport
        self.host_resolver = host_resolver or _resolve_host_ips

    async def ingest(self, url: str) -> MenuIngestionResult:
        if not self._is_public_http_url(url):
            return MenuIngestionResult(status="invalid_url")
        try:
            async with httpx.AsyncClient(
                follow_redirects=False,
                timeout=self.timeout_seconds,
                transport=self.transport,
            ) as client:
                response = await self._fetch_with_validated_redirects(client, url)
        except (httpx.HTTPError, ValueError):
            return MenuIngestionResult(status="fetch_failed")
        if response is None:
            return MenuIngestionResult(status="invalid_url")

        content = response.content.decode(
            response.encoding or "utf-8",
            errors="ignore",
        )
        excerpt = extract_menu_excerpt(
            content,
            content_type=response.content_type,
        )
        if excerpt is None:
            return MenuIngestionResult(status="empty")
        return MenuIngestionResult(status="ok", excerpt=excerpt)

    async def _fetch_with_validated_redirects(
        self,
        client: httpx.AsyncClient,
        url: str,
    ) -> _FetchedMenuResponse | None:
        current_url = url
        for _ in range(MAX_MENU_REDIRECTS + 1):
            if not self._is_public_http_url(current_url):
                return None
            async with client.stream(
                "GET",
                current_url,
                headers={"Accept": "text/html,text/plain;q=0.9"},
            ) as response:
                if response.is_redirect:
                    location = response.headers.get("location")
                    if not location:
                        response.raise_for_status()
                    current_url = urljoin(str(response.url), location)
                    continue
                response.raise_for_status()
                return _FetchedMenuResponse(
                    content=await self._read_capped_content(response),
                    content_type=response.headers.get("content-type", ""),
                    encoding=response.encoding,
                )
        raise httpx.TooManyRedirects("Menu URL exceeded redirect limit")

    async def _read_capped_content(self, response: httpx.Response) -> bytes:
        chunks: list[bytes] = []
        total_bytes = 0
        async for chunk in response.aiter_bytes():
            remaining = MAX_MENU_BYTES - total_bytes
            if remaining <= 0:
                break
            chunks.append(chunk[:remaining])
            total_bytes += min(len(chunk), remaining)
        return b"".join(chunks)

    def _is_public_http_url(self, url: str) -> bool:
        try:
            parsed = urlparse(url)
            _ = parsed.port
        except ValueError:
            return False
        if parsed.scheme not in {"http", "https"} or not parsed.netloc or not parsed.hostname:
            return False
        if self._is_blocked_host(parsed.hostname):
            return False
        try:
            resolved_addresses = list(self.host_resolver(parsed.hostname, parsed.port))
        except OSError:
            return False
        return bool(resolved_addresses) and not any(
            self._is_blocked_host(address) for address in resolved_addresses
        )

    @staticmethod
    def _is_blocked_host(hostname: str) -> bool:
        normalized = hostname.strip("[]").lower().rstrip(".")
        if normalized in _BLOCKED_HOSTS or normalized.endswith(_BLOCKED_HOST_SUFFIXES):
            return True
        try:
            ip_address = ipaddress.ip_address(normalized)
        except ValueError:
            return False
        return (
            ip_address.is_loopback
            or ip_address.is_private
            or ip_address.is_link_local
            or ip_address.is_multicast
            or ip_address.is_reserved
            or ip_address.is_unspecified
        )


def _resolve_host_ips(hostname: str, port: int | None) -> Iterable[str]:
    return {
        address[0]
        for *_, address in socket.getaddrinfo(
            hostname,
            port or 443,
            type=socket.SOCK_STREAM,
        )
    }


def extract_menu_excerpt(content: str, *, content_type: str = "") -> str | None:
    if "html" in content_type.lower() or "<html" in content[:500].lower():
        parser = _MenuTextParser()
        parser.feed(content)
        content = parser.text
    normalized = " ".join(content.split())
    if not normalized:
        return None
    return normalized[:MAX_MENU_EXCERPT_CHARS]


def extract_menu_highlights(excerpt: str | None) -> list[str]:
    normalized = _normalize_menu_excerpt(excerpt)
    if not normalized:
        return []

    return list(dict.fromkeys([*_price_highlights(normalized), *_term_highlights(normalized)]))[
        :MAX_MENU_HIGHLIGHTS
    ]


def _normalize_menu_excerpt(excerpt: str | None) -> str:
    if excerpt is None:
        return ""
    return " ".join(excerpt.split()).lower()


def _price_highlights(normalized: str) -> list[str]:
    price_match = _PRICE_PATTERN.search(normalized)
    if price_match is None:
        return []
    return [price_match.group(0).replace(" ", "")]


def _term_highlights(normalized: str) -> list[str]:
    return [
        label
        for label, terms in _MENU_HIGHLIGHT_RULES
        if any(term in normalized for term in terms)
    ]


class _MenuTextParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self._text_parts: list[str] = []
        self._ignored_depth = 0

    @property
    def text(self) -> str:
        return " ".join(self._text_parts)

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        del attrs
        if tag.lower() in {"script", "style", "noscript"}:
            self._ignored_depth += 1

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() in {"script", "style", "noscript"} and self._ignored_depth > 0:
            self._ignored_depth -= 1

    def handle_data(self, data: str) -> None:
        if self._ignored_depth == 0:
            self._text_parts.append(data)
