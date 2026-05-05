from __future__ import annotations

import httpx
import pytest

from dogswipe_backend.menu import HTTPMenuIngestor, extract_menu_excerpt, extract_menu_highlights


def test_extract_menu_excerpt_strips_html_noise() -> None:
    excerpt = extract_menu_excerpt(
        """
        <html>
          <head><style>.hidden { display: none; }</style></head>
          <body>
            <h1>Boardwalk Dogs</h1>
            <script>window.secret = "not menu";</script>
            <p>Classic snap, mustard, relish, and onion.</p>
          </body>
        </html>
        """,
        content_type="text/html",
    )

    assert excerpt == "Boardwalk Dogs Classic snap, mustard, relish, and onion."


def test_extract_menu_highlights_returns_short_food_signals() -> None:
    highlights = extract_menu_highlights(
        "Boardwalk Snap $6.25 classic dog, mustard, relish, onion, and celery salt."
    )

    assert highlights == ["$6.25", "Classic", "Mustard", "Relish"]


def test_extract_menu_highlights_handles_empty_snapshots() -> None:
    assert extract_menu_highlights(None) == []
    assert extract_menu_highlights("   ") == []


@pytest.mark.asyncio
async def test_http_menu_ingestor_rejects_non_http_urls() -> None:
    result = await HTTPMenuIngestor().ingest("file:///tmp/menu.html")

    assert result.status == "invalid_url"
    assert result.excerpt is None


@pytest.mark.asyncio
async def test_http_menu_ingestor_extracts_html_snapshot() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.headers["accept"] == "text/html,text/plain;q=0.9"
        return httpx.Response(
            200,
            headers={"content-type": "text/html; charset=utf-8"},
            text="<h1>Boardwalk Dogs</h1><p>Classic snap with mustard and onion.</p>",
        )

    result = await HTTPMenuIngestor(transport=httpx.MockTransport(handler)).ingest(
        "https://boardwalk.example.com/menu"
    )

    assert result.status == "ok"
    assert result.excerpt == "Boardwalk Dogs Classic snap with mustard and onion."


@pytest.mark.asyncio
async def test_http_menu_ingestor_records_fetch_failure() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        del request
        return httpx.Response(503)

    result = await HTTPMenuIngestor(transport=httpx.MockTransport(handler)).ingest(
        "https://boardwalk.example.com/menu"
    )

    assert result.status == "fetch_failed"
    assert result.excerpt is None
