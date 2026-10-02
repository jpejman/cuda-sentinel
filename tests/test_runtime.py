import os
import unittest
from tempfile import TemporaryDirectory

from cuda_sentinel.agent import parse_kernel_lines
from cuda_sentinel.models import RemediationAudit, RemediationProposal
from cuda_sentinel.remediation import RemediationService
from cuda_sentinel.store import SentinelStore
from cuda_sentinel.gpu import inventory


class RuntimeTests(unittest.TestCase):
    def test_kernel_parser_filters_and_stabilizes_ids(self):
        lines = ["normal boot", "NVRM: Xid (PCI:0000:65:00): 31"]
        first = parse_kernel_lines(lines, host="test-host")
        second = parse_kernel_lines(lines, host="test-host")
        self.assertEqual(len(first), 1)
        self.assertEqual(first[0].severity, "high")
        self.assertEqual(first[0].id, second[0].id)

    def test_store_deduplicates_events(self):
        store = SentinelStore()
        event = parse_kernel_lines(["NVRM: Xid 31"], host="test-host")[0]
        self.assertTrue(store.add_event(event))
        self.assertFalse(store.add_event(event))

    def test_store_persists_events_and_audits_across_restarts(self):
        with TemporaryDirectory() as state_dir:
            event = parse_kernel_lines(["NVRM: Xid 31"], host="test-host")[0]
            first = SentinelStore(state_dir)
            first.add_event(event)
            first.add_audit(RemediationAudit(proposal_id="p1", approved=True, dry_run=True, status="dry_run", message="test"))
            second = SentinelStore(state_dir)
            self.assertEqual(second.events()[0].id, event.id)
            self.assertEqual(second.audits()[0].proposal_id, "p1")

    def test_remediation_requires_approval_and_is_dry_run(self):
        service = RemediationService()
        proposal = RemediationProposal(id="p1", title="Reset GPU", rationale="Targeted reset", risk="high", command="nvidia-smi --gpu-reset -i 0")
        self.assertEqual(service.apply(proposal, approved=False, dry_run=True).status, "failed")
        self.assertEqual(service.apply(proposal, approved=True, dry_run=True).status, "dry_run")

    def test_remediation_rejects_arbitrary_commands(self):
        service = RemediationService()
        proposal = RemediationProposal(id="p2", title="Unsafe", rationale="Unsafe test", risk="critical", command="rm -rf /")
        self.assertEqual(service.apply(proposal, approved=True, dry_run=True).status, "failed")

    def test_api_exposes_health_metrics_and_audit(self):
        from fastapi.testclient import TestClient
        from cuda_sentinel.api import app

        client = TestClient(app)
        health = client.get("/v1/health")
        self.assertTrue(health.json()["ok"])
        self.assertIn("events", health.json())
        self.assertEqual(client.get("/v1/metrics").status_code, 200)
        self.assertEqual(client.get("/v1/remediation/audit").status_code, 200)

    def test_gpu_inventory_is_safe_without_nvidia_tooling(self):
        self.assertIsInstance(inventory(), list)

    def test_operator_auth_protects_mutating_routes_when_configured(self):
        from fastapi.testclient import TestClient
        from cuda_sentinel.api import app

        previous = os.environ.get("SENTINEL_OPERATOR_TOKEN")
        os.environ["SENTINEL_OPERATOR_TOKEN"] = "test-token"
        try:
            client = TestClient(app)
            payload = {"id": "evt-auth", "host": "test", "source": "test", "type": "test", "severity": "info", "message": "test"}
            self.assertEqual(client.post("/v1/events", json=payload).status_code, 401)
            self.assertEqual(client.post("/v1/events", json=payload, headers={"Authorization": "Bearer test-token"}).status_code, 201)
        finally:
            if previous is None:
                os.environ.pop("SENTINEL_OPERATOR_TOKEN", None)
            else:
                os.environ["SENTINEL_OPERATOR_TOKEN"] = previous


if __name__ == "__main__":
    unittest.main()
