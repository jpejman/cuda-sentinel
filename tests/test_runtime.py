import unittest

from cuda_sentinel.agent import parse_kernel_lines
from cuda_sentinel.models import RemediationProposal
from cuda_sentinel.remediation import RemediationService
from cuda_sentinel.store import SentinelStore


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

    def test_remediation_requires_approval_and_is_dry_run(self):
        service = RemediationService()
        proposal = RemediationProposal(id="p1", title="Reset GPU", rationale="Targeted reset", risk="high", command="nvidia-smi --gpu-reset -i 0")
        self.assertEqual(service.apply(proposal, approved=False, dry_run=True).status, "failed")
        self.assertEqual(service.apply(proposal, approved=True, dry_run=True).status, "dry_run")

    def test_remediation_rejects_arbitrary_commands(self):
        service = RemediationService()
        proposal = RemediationProposal(id="p2", title="Unsafe", rationale="Unsafe test", risk="critical", command="rm -rf /")
        self.assertEqual(service.apply(proposal, approved=True, dry_run=True).status, "failed")


if __name__ == "__main__":
    unittest.main()
