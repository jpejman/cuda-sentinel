# News Update Agent: How to Run

This repository includes a runnable agent script: `news_update_agent.py`.

## 1) Run once (single fetch + process)

```bash
python news_update_agent.py --keyword ai --max-items 20 --output news_report.json
```

## 2) Run continuously (agent mode)

```bash
python news_update_agent.py --keyword ai --interval-seconds 300 --output news_report.json
```

That command refreshes `news_report.json` every 5 minutes.

## 3) Use custom feeds

```bash
python news_update_agent.py \
  --feed https://feeds.bbci.co.uk/news/rss.xml \
  --feed https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml \
  --keyword economy \
  --output news_report.json
```

## Notes

- Yes — this "agent" is intentionally a Python program you execute.
- You can run it manually, under `cron`, in a systemd service, or in a container.
- Output is structured JSON intended for downstream automation.
