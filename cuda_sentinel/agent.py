import hashlib
import re
import socket
from collections.abc import Iterable
from .models import Event, Severity, utc_now

def parse_kernel_lines(lines: Iterable[str], host: str | None = None) -> list[Event]:
    """Convert relevant kernel lines into stable, deduplicatable events."""
    host_name = host or socket.gethostname()
    events: list[Event] = []
    for line in lines:
        if not re.search(r"(?:Xid|NVRM|nvidia|gpu)", line, re.IGNORECASE):
            continue
        severity: Severity = "high" if re.search(r"Xid|fallen off the bus", line, re.IGNORECASE) else "info"
        event_type = "XID" if re.search(r"Xid", line, re.IGNORECASE) else "KERNEL_GPU"
        event_id = hashlib.sha256(f"{host_name}\0{line}".encode()).hexdigest()[:20]
        events.append(Event(id=f"evt_{event_id}", timestamp=utc_now(), host=host_name, source="kernel", type=event_type, severity=severity, message=line[:2000], raw=line[:4000]))
    return events
