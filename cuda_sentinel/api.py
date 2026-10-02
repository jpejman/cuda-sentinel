import json
import logging
import os
import time
from fastapi import FastAPI, HTTPException, Request
from .models import Event, RemediationAudit, RemediationProposal, RemediationRequest, RemediationResult, Service
from .remediation import RemediationService
from .store import SentinelStore
from .gpu import inventory

store = SentinelStore(os.environ.get("SENTINEL_STATE_DIR", "/var/lib/cuda-sentinel"))
store.set_services([Service(id="api", name="sentinel-api", version="0.2.0", status="healthy", host=os.environ.get("HOSTNAME", "localhost"))])
store.set_proposals([RemediationProposal(id="p1", title="Reset GPU-0", rationale="Targeted reset for an unresponsive GPU.", risk="high", command="nvidia-smi --gpu-reset -i 0")])
remediation = RemediationService()
app = FastAPI(title="CUDA Sentinel API", version="0.2.0")
logger = logging.getLogger("cuda_sentinel.api")
if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
    logger.addHandler(handler)
    logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

@app.middleware("http")
async def request_logging(request: Request, call_next):
    started = time.perf_counter()
    response = await call_next(request)
    logger.info("http_request %s", json.dumps({"method": request.method, "path": request.url.path, "status": response.status_code, "duration_ms": round((time.perf_counter() - started) * 1000, 2)}))
    return response

@app.get("/v1/health")
def health() -> dict[str, str | bool]:
    return {"ok": True, "version": "0.2.0", "events": len(store.events()), "remediation_audits": len(store.audits())}

@app.get("/v1/metrics")
def metrics() -> dict[str, int]:
    return {"events_total": len(store.events()), "remediation_audits_total": len(store.audits())}

@app.get("/v1/gpus", response_model=list)
def gpus():
    return inventory()

@app.get("/v1/services", response_model=list[Service])
def services() -> list[Service]:
    return store.services()

@app.get("/v1/events", response_model=list[Event])
def events() -> list[Event]:
    return store.events()[-100:]

@app.post("/v1/events", response_model=Event, status_code=201)
def ingest_event(event: Event) -> Event:
    store.add_event(event)
    return event

@app.get("/v1/proposals", response_model=list[RemediationProposal])
def proposals() -> list[RemediationProposal]:
    return store.proposals()

@app.get("/v1/remediation/audit", response_model=list[RemediationAudit])
def remediation_audit() -> list[RemediationAudit]:
    return store.audits()[-100:]

@app.post("/v1/proposals/{proposal_id}/apply", response_model=RemediationResult)
def apply_proposal(proposal_id: str, request: RemediationRequest) -> RemediationResult:
    proposal = store.proposal(proposal_id)
    if proposal is None:
        raise HTTPException(status_code=404, detail="Proposal not found")
    result = remediation.apply(proposal, approved=request.approved, dry_run=request.dry_run)
    store.add_audit(RemediationAudit(proposal_id=proposal_id, approved=request.approved, dry_run=request.dry_run, status=result.status, message=result.message))
    return result

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "5001")))
