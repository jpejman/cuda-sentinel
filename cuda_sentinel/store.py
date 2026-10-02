import json
from pathlib import Path
from threading import Lock
from .models import Event, RemediationAudit, RemediationProposal, Service

class SentinelStore:
    """Small in-memory store used until durable persistence is introduced."""
    def __init__(self, state_dir: str | Path | None = None) -> None:
        self._lock = Lock()
        self._events: list[Event] = []
        self._audits: list[RemediationAudit] = []
        self._services: list[Service] = []
        self._proposals: list[RemediationProposal] = []
        self._state_dir = Path(state_dir) if state_dir else None
        if self._state_dir:
            self._state_dir.mkdir(parents=True, exist_ok=True)
            self._events = self._load(Event, "events.jsonl")
            self._audits = self._load(RemediationAudit, "remediation_audit.jsonl")

    def _load(self, model: type, filename: str) -> list:
        path = self._state_dir / filename
        if not path.exists():
            return []
        records = []
        for line in path.read_text(encoding="utf-8").splitlines():
            try:
                records.append(model.model_validate_json(line))
            except ValueError:
                continue
        return records

    def _append(self, filename: str, model: object) -> None:
        if self._state_dir:
            with (self._state_dir / filename).open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(model.model_dump(mode="json"), sort_keys=True) + "\n")

    def add_event(self, event: Event) -> bool:
        with self._lock:
            if any(existing.id == event.id for existing in self._events):
                return False
            self._events.append(event)
            self._events = self._events[-1000:]
            self._append("events.jsonl", event)
            return True

    def events(self) -> list[Event]:
        with self._lock:
            return list(self._events)

    def set_services(self, services: list[Service]) -> None:
        with self._lock:
            self._services = list(services)

    def services(self) -> list[Service]:
        with self._lock:
            return list(self._services)

    def set_proposals(self, proposals: list[RemediationProposal]) -> None:
        with self._lock:
            self._proposals = list(proposals)

    def proposals(self) -> list[RemediationProposal]:
        with self._lock:
            return list(self._proposals)

    def proposal(self, proposal_id: str) -> RemediationProposal | None:
        with self._lock:
            return next((item for item in self._proposals if item.id == proposal_id), None)

    def add_audit(self, audit: RemediationAudit) -> None:
        with self._lock:
            self._audits.append(audit)
            self._audits = self._audits[-1000:]
            self._append("remediation_audit.jsonl", audit)

    def audits(self) -> list[RemediationAudit]:
        with self._lock:
            return list(self._audits)
