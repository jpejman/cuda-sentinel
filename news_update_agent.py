#!/usr/bin/env python3
"""News Update Agent.

Usage examples:
  python news_update_agent.py --keyword ai --max-items 20 --output report.json
  python news_update_agent.py --feed https://example.com/rss --interval-seconds 300

The optional ``--interval-seconds`` mode makes this behave like a long-running
agent that periodically refreshes the report file.
"""

from __future__ import annotations

import argparse
import json
import re
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from collections import Counter
from dataclasses import asdict, dataclass
from email.utils import parsedate_to_datetime
from html import unescape
from typing import Iterable

DEFAULT_FEEDS = [
    "https://feeds.bbci.co.uk/news/rss.xml",
    "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml",
    "https://www.aljazeera.com/xml/rss/all.xml",
]

STOP_WORDS = {
    "a",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "but",
    "by",
    "for",
    "from",
    "has",
    "he",
    "in",
    "is",
    "it",
    "its",
    "of",
    "on",
    "that",
    "the",
    "to",
    "was",
    "were",
    "will",
    "with",
}


@dataclass
class NewsItem:
    source: str
    title: str
    link: str
    published: str
    summary: str


@dataclass
class NewsReport:
    generated_at_epoch: int
    total_items: int
    keywords: list[str]
    matched_items: list[NewsItem]
    top_terms: list[tuple[str, int]]


class NewsUpdateAgent:
    def __init__(self, feeds: Iterable[str], user_agent: str = "NewsUpdateAgent/1.0") -> None:
        self.feeds = list(feeds)
        self.user_agent = user_agent

    def fetch_feed(self, feed_url: str, timeout: int = 12) -> list[NewsItem]:
        request = urllib.request.Request(feed_url, headers={"User-Agent": self.user_agent})
        with urllib.request.urlopen(request, timeout=timeout) as response:
            data = response.read()

        root = ET.fromstring(data)
        items: list[NewsItem] = []

        for item in root.findall(".//item"):
            title = clean_text(item.findtext("title", default="").strip())
            if not title:
                continue

            link = item.findtext("link", default="").strip()
            pub_date = item.findtext("pubDate", default="").strip()
            description = clean_text(item.findtext("description", default="").strip())
            source = item.findtext("source", default="").strip() or domain_from_url(feed_url)

            items.append(
                NewsItem(
                    source=source,
                    title=title,
                    link=link,
                    published=normalize_pub_date(pub_date),
                    summary=description,
                )
            )

        return items

    def collect_items(self) -> list[NewsItem]:
        collected: list[NewsItem] = []
        seen_links: set[str] = set()

        for feed in self.feeds:
            try:
                feed_items = self.fetch_feed(feed)
            except Exception as exc:  # keep processing other feeds
                print(f"[warn] Failed to fetch {feed}: {exc}")
                continue

            for item in feed_items:
                if not item.link or item.link in seen_links:
                    continue
                seen_links.add(item.link)
                collected.append(item)

        return collected

    def process(self, keywords: Iterable[str], max_items: int = 30) -> NewsReport:
        prepared_keywords = [k.strip().lower() for k in keywords if k.strip()]
        items = self.collect_items()

        if prepared_keywords:
            filtered = [
                item
                for item in items
                if contains_keywords(item.title + " " + item.summary, prepared_keywords)
            ]
        else:
            filtered = items

        filtered = sorted(filtered, key=lambda i: i.published, reverse=True)[:max_items]
        top_terms = calculate_top_terms(filtered)

        return NewsReport(
            generated_at_epoch=int(time.time()),
            total_items=len(filtered),
            keywords=prepared_keywords,
            matched_items=filtered,
            top_terms=top_terms,
        )


def clean_text(raw: str) -> str:
    without_tags = re.sub(r"<[^>]+>", " ", raw)
    return re.sub(r"\s+", " ", unescape(without_tags)).strip()


def contains_keywords(text: str, keywords: list[str]) -> bool:
    text_lower = text.lower()
    return any(keyword in text_lower for keyword in keywords)


def tokenize(text: str) -> list[str]:
    return [tok for tok in re.findall(r"[a-zA-Z]{3,}", text.lower()) if tok not in STOP_WORDS]


def calculate_top_terms(items: list[NewsItem], top_n: int = 12) -> list[tuple[str, int]]:
    counts = Counter()
    for item in items:
        counts.update(tokenize(item.title + " " + item.summary))
    return counts.most_common(top_n)


def normalize_pub_date(pub_date: str) -> str:
    if not pub_date:
        return ""
    try:
        return parsedate_to_datetime(pub_date).isoformat()
    except Exception:
        return pub_date


def domain_from_url(url: str) -> str:
    return re.sub(r"^www\.", "", urllib.parse.urlparse(url).hostname or "unknown-source")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fetch and process updates from news RSS feeds.")
    parser.add_argument(
        "--feed",
        action="append",
        dest="feeds",
        default=[],
        help="RSS feed URL (repeat for multiple). Defaults to a predefined set.",
    )
    parser.add_argument(
        "--keyword",
        action="append",
        dest="keywords",
        default=[],
        help="Keyword filter (repeat for multiple). If omitted, all items are returned.",
    )
    parser.add_argument("--max-items", type=int, default=30, help="Maximum items in the output report.")
    parser.add_argument("--output", default="news_report.json", help="Output JSON path.")
    parser.add_argument(
        "--interval-seconds",
        type=int,
        default=0,
        help=(
            "Run continuously and refresh output every N seconds. "
            "Set to 0 (default) to run once."
        ),
    )
    return parser.parse_args()


def run_once(feeds: list[str], keywords: list[str], max_items: int, output_path: str) -> None:
    agent = NewsUpdateAgent(feeds=feeds)
    report = agent.process(keywords=keywords, max_items=max_items)

    serializable_report = asdict(report)
    with open(output_path, "w", encoding="utf-8") as fh:
        json.dump(serializable_report, fh, indent=2)

    print(f"Saved report with {report.total_items} items to {output_path}")


def main() -> None:
    args = parse_args()
    feeds = args.feeds or DEFAULT_FEEDS

    if args.interval_seconds <= 0:
        run_once(feeds, args.keywords, args.max_items, args.output)
        return

    print(f"Starting news agent loop. Refresh interval: {args.interval_seconds}s")
    while True:
        run_once(feeds, args.keywords, args.max_items, args.output)
        time.sleep(args.interval_seconds)


if __name__ == "__main__":
    main()
