import os
from fastapi import FastAPI, HTTPException
from .models import Event, RemediationRequest, RemediationResult, Service
from .remediation import RemediationService
from .store import SentinelStore

store = SentinelStore()
store.set_services([Service(id="api", name="sentinel-api", version="0.2.0", status="healthy", host=os.environ.get("HOSTNAME", "localhost"))])
remediation = RemediationService()
app = FastAPI(title="CUDA Sentinel API", version="0.2.0")

@app.get("/v1/health")
def health() -> dict[str, str | bool]:
    return {"ok": True, "version": "0.2.0"}

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

@app.get("/v1/proposals")
def proposals():
    return store.proposals()

@app.post("/v1/proposals/{proposal_id}/apply", response_model=RemediationResult)
def apply_proposal(proposal_id: str, request: RemediationRequest) -> RemediationResult:
    proposal = store.proposal(proposal_id)
    if proposal is None:
        raise HTTPException(status_code=404, detail="Proposal not found")
    return remediation.apply(proposal, approved=request.approved, dry_run=request.dry_run)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "5001")))
