from dataclasses import dataclass
from .models import RemediationProposal, RemediationResult

@dataclass(frozen=True)
class RemediationPolicy:
    allowed_commands: frozenset[str] = frozenset({
        "nvidia-smi -pm 1",
        "nvidia-smi --gpu-reset -i 0",
        "systemctl restart llm-infer.service",
    })

class RemediationService:
    def __init__(self, policy: RemediationPolicy | None = None) -> None:
        self.policy = policy or RemediationPolicy()

    def apply(self, proposal: RemediationProposal, *, approved: bool, dry_run: bool) -> RemediationResult:
        if proposal.command not in self.policy.allowed_commands:
            return RemediationResult(proposal_id=proposal.id, status="failed", dry_run=dry_run, message="Command is not present in the remediation allowlist.")
        if not approved:
            return RemediationResult(proposal_id=proposal.id, status="failed", dry_run=dry_run, message="Explicit approval is required before remediation.")
        if dry_run:
            return RemediationResult(proposal_id=proposal.id, status="dry_run", dry_run=True, message=f"Dry run accepted for: {proposal.command}")
        return RemediationResult(proposal_id=proposal.id, status="failed", dry_run=False, message="Live execution is disabled until an audited executor is implemented.")
