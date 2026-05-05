from __future__ import annotations

import re
from dataclasses import dataclass
from html.parser import HTMLParser
from typing import Protocol
from urllib.parse import urlparse

import httpx

MAX_MENU_BYTES = 100_000
MAX_MENU_EXCERPT_CHARS = 500
MAX_MENU_HIGHLIGHTS = 4
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


@dataclass(frozen=True)
class MenuIngestionResult:
    status: str
    excerpt: str | None = None


class MenuIngestor(Protocol):
    async def ingest(self, url: str) -> MenuIngestionResult:
        raise NotImplementedError


class HTTPMenuIngestor:
    def __init__(
        self,
        *,
        timeout_seconds: float = 5.0,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self.timeout_seconds = timeout_seconds
        self.transport = transport

    async def ingest(self, url: str) -> MenuIngestionResult:
        if not self._is_http_url(url):
            return MenuIngestionResult(status="invalid_url")
        try:
            async with httpx.AsyncClient(
                follow_redirects=True,
                timeout=self.timeout_seconds,
                transport=self.transport,
            ) as client:
                response = await client.get(
                    url,
                    headers={"Accept": "text/html,text/plain;q=0.9"},
                )
                response.raise_for_status()
        except httpx.HTTPError:
            return MenuIngestionResult(status="fetch_failed")

        content = response.content[:MAX_MENU_BYTES].decode(
            response.encoding or "utf-8",
            errors="ignore",
        )
        excerpt = extract_menu_excerpt(
            content,
            content_type=response.headers.get("content-type", ""),
        )
        if excerpt is None:
            return MenuIngestionResult(status="empty")
        return MenuIngestionResult(status="ok", excerpt=excerpt)

    @staticmethod
    def _is_http_url(url: str) -> bool:
        parsed = urlparse(url)
        return parsed.scheme in {"http", "https"} and bool(parsed.netloc)


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
