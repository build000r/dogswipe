from __future__ import annotations

from dataclasses import dataclass
from html.parser import HTMLParser
from typing import Protocol
from urllib.parse import urlparse

import httpx

MAX_MENU_BYTES = 100_000
MAX_MENU_EXCERPT_CHARS = 500


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
