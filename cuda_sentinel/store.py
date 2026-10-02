from threading import Lock
from .models import Event, RemediationProposal, Service

class SentinelStore:
    """Small in-memory store used until durable persistence is introduced."""
    def __init__(self) -> None:
        self._lock = Lock()
        self._events: list[Event] = []
        self._services: list[Service] = []
        self._proposals: list[RemediationProposal] = []

    def add_event(self, event: Event) -> bool:
        with self._lock:
            if any(existing.id == event.id for existing in self._events):
                return False
            self._events.append(event)
            self._events = self._events[-1000:]
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
