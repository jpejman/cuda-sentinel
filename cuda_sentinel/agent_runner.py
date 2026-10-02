import json
import logging
import os
import subprocess
import time
import urllib.request

from .agent import parse_kernel_lines


def read_kernel_lines() -> list[str]:
    try:
        result = subprocess.run(["dmesg", "--ctime"], check=False, capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return [f"DMESG_ERR: {exc}"]
    if result.returncode != 0:
        return [f"DMESG_ERR: {result.stderr.strip() or 'dmesg failed'}"]
    return result.stdout.splitlines()


def publish_events(events: list[object], endpoint: str) -> None:
    for event in events:
        payload = json.dumps(event.model_dump(mode="json")).encode()
        request = urllib.request.Request(endpoint, data=payload, headers={"Content-Type": "application/json"}, method="POST")
        try:
            with urllib.request.urlopen(request, timeout=5):
                pass
        except OSError as exc:
            logging.warning("event publish failed: %s", exc)


def main() -> None:
    logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
    endpoint = os.environ.get("SENTINEL_EVENTS_URL", "http://127.0.0.1:5001/v1/events")
    interval = max(5, int(os.environ.get("SENTINEL_POLL_SECONDS", "10")))
    last_ids: set[str] = set()
    while True:
        events = parse_kernel_lines(read_kernel_lines())
        new_events = [event for event in events if event.id not in last_ids]
        publish_events(new_events, endpoint)
        last_ids = {event.id for event in events}
        time.sleep(interval)


if __name__ == "__main__":
    main()
