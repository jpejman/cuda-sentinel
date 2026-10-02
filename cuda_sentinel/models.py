from datetime import datetime, timezone
from typing import Literal
from pydantic import BaseModel, Field

Severity = Literal["info", "low", "medium", "high", "critical"]
ProposalStatus = Literal["ready", "dry_run", "approved", "running", "done", "failed"]

def utc_now() -> datetime:
    return datetime.now(timezone.utc)

class Service(BaseModel):
    id: str
    name: str
    version: str
    status: Literal["healthy", "degraded", "failed", "unknown"]
    host: str

class Event(BaseModel):
    id: str
    timestamp: datetime = Field(default_factory=utc_now)
    host: str
    gpu_index: int | None = Field(default=None, ge=0)
    source: str
    type: str
    severity: Severity
    message: str = Field(min_length=1, max_length=2000)
    raw: str = Field(default="", max_length=4000)

class RemediationProposal(BaseModel):
    id: str
    title: str
    rationale: str
    risk: Literal["low", "medium", "high", "critical"]
    command: str
    status: ProposalStatus = "ready"
    dry_run: bool = True

class RemediationRequest(BaseModel):
    approved: bool = False
    dry_run: bool = True

class RemediationResult(BaseModel):
    proposal_id: str
    status: ProposalStatus
    dry_run: bool
    message: str
