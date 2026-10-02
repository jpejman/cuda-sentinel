import React, { useEffect, useMemo, useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Progress } from "@/components/ui/progress";
import { AlertTriangle, CheckCircle2, Cpu, PlayCircle, RefreshCw, Shield, Workflow } from "lucide-react";
import { ResponsiveContainer, LineChart, Line, XAxis, YAxis, Tooltip, Area, AreaChart } from "recharts";

// --- Mocked Data (replace with /api once backend is wired) ---
const servicesSeed = [
  { id: "agent", name: "sentinel-agent", version: "0.1.0", status: "healthy", uptime: "2d 4h", host: "gpu-host-01" },
  { id: "orchestrator", name: "sentinel-orchestrator", version: "0.1.0", status: "degraded", uptime: "1d 23m", host: "ctrl-01" },
  { id: "executor", name: "sentinel-executor", version: "0.1.0", status: "healthy", uptime: "2d 2h", host: "gpu-host-01" },
  { id: "api", name: "sentinel-api", version: "0.1.0", status: "healthy", uptime: "3d 9h", host: "ctrl-01" },
  { id: "dashboard", name: "sentinel-dashboard", version: "0.1.0", status: "healthy", uptime: "3d 9h", host: "ctrl-01" },
  { id: "dcgm", name: "connector-dcgm", version: "0.1.0", status: "unknown", uptime: "--", host: "gpu-host-01" },
];

const gpuSeries = Array.from({ length: 24 }).map((_, i) => ({
  t: `${i}:00`,
  util: Math.max(0, 50 + Math.round(30 * Math.sin(i / 4))) + (i % 5 === 0 ? 10 : 0),
  mem: Math.max(0, 60 + Math.round(25 * Math.cos(i / 3)))
}));

const eventsSeed = [
  { id: "e1", time: "09:14:03", host: "gpu-host-01", gpu: 0, severity: "high", type: "Xid-31", summary: "GPU has fallen off the bus", raw: "NVRM: Xid (PCI:0000:65:00): 31, ..." },
  { id: "e2", time: "09:20:11", host: "gpu-host-01", gpu: 0, severity: "medium", type: "LIB_MISMATCH", summary: "torch compiled for CUDA 12.1, runtime 12.4", raw: "libcudart.so => /usr/local/cuda-12.4/..." },
  { id: "e3", time: "09:22:47", host: "gpu-host-01", gpu: 1, severity: "low", type: "ECC_CORRECTABLE", summary: "Correctable ECC spike (4 events)", raw: "ECC counter += 4" },
];

const proposalsSeed = [
  {
    id: "p1",
    title: "Reset GPU-0 + restart llm-infer",
    rationale: "Xid-31 indicates the device is unresponsive. A targeted reset often restores the channel without reboot.",
    impact: "<15s service blip on GPU-0",
    steps: [
      "nvidia-smi -pm 1",
      "nvidia-smi --gpu-reset -i 0",
      "systemctl restart llm-infer.service"
    ],
    safety: ["No global reboot", "Affects only GPU-0", "Idempotent"],
    status: "ready"
  },
  {
    id: "p2",
    title: "Reconcile CUDA libs to 12.1 (match torch)",
    rationale: "Userspace mismatch between torch (12.1) and runtime (12.4). Point /usr/local/cuda => 12.1 & ldconfig.",
    impact: "~5s PATH/LD cache refresh",
    steps: [
      "update-alternatives --set cuda /usr/local/cuda-12.1",
      "ldconfig"
    ],
    safety: ["Reversible", "No process kill"],
    status: "ready"
  }
];

// --- UI Helpers ---
const SevDot: React.FC<{ sev: string }> = ({ sev }) => {
  const m: Record<string, string> = { high: "bg-red-500", medium: "bg-yellow-500", low: "bg-blue-500", info: "bg-gray-400" };
  return <span className={`inline-block w-2 h-2 rounded-full mr-2 ${m[sev] || "bg-gray-400"}`} />;
};

const StatusBadge: React.FC<{ status: string }> = ({ status }) => {
  const colors: Record<string, string> = {
    healthy: "bg-emerald-100 text-emerald-900",
    degraded: "bg-amber-100 text-amber-900",
    failed: "bg-rose-100 text-rose-900",
    unknown: "bg-slate-100 text-slate-900",
  };
  return <Badge className={`${colors[status] || colors.unknown} capitalize`}>{status}</Badge>;
};

export default function CudaSentinelDashboard() {
  const [services, setServices] = useState(servicesSeed);
  const [events, setEvents] = useState(eventsSeed);
  const [proposals, setProposals] = useState(proposalsSeed);
  const [filter, setFilter] = useState("");

  useEffect(() => {
    const apiBase = (import.meta as any).env?.VITE_SENTINEL_API || "http://127.0.0.1:5001";
    const load = async () => {
      try {
        const [serviceResponse, eventResponse, proposalResponse] = await Promise.all([
          fetch(`${apiBase}/v1/services`),
          fetch(`${apiBase}/v1/events`),
          fetch(`${apiBase}/v1/proposals`),
        ]);
        if (serviceResponse.ok) setServices(await serviceResponse.json());
        if (eventResponse.ok) {
          const apiEvents = await eventResponse.json();
          setEvents(apiEvents.map((event: any) => ({ ...event, time: event.timestamp, gpu: event.gpu_index, summary: event.message })));
        }
        if (proposalResponse.ok) {
          const apiProposals = await proposalResponse.json();
          setProposals(apiProposals.map((proposal: any) => ({ ...proposal, impact: `Risk: ${proposal.risk}`, steps: [proposal.command], safety: [proposal.dry_run ? "Dry-run by default" : "Approval required"] })));
        }
      } catch (error) {
        console.warn("CUDA Sentinel API unavailable; showing demo data", error);
      }
    };
    void load();
  }, []);

  const filteredEvents = useMemo(
    () => events.filter(e => (filter ? (e.type.toLowerCase().includes(filter.toLowerCase()) || e.summary.toLowerCase().includes(filter.toLowerCase())) : true)),
    [events, filter]
  );

  const applyFix = async (id: string) => {
    const apiBase = (import.meta as any).env?.VITE_SENTINEL_API || "http://127.0.0.1:5001";
    setProposals(prev => prev.map(p => p.id === id ? { ...p, status: "running" } : p));
    try {
      const response = await fetch(`${apiBase}/v1/proposals/${id}/apply`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ approved: true, dry_run: true }),
      });
      const result = await response.json();
      setProposals(prev => prev.map(p => p.id === id ? { ...p, status: result.status } : p));
    } catch (error) {
      console.warn("Proposal request failed", error);
      setProposals(prev => prev.map(p => p.id === id ? { ...p, status: "failed" } : p));
    }
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Shield className="w-7 h-7" />
          <h1 className="text-2xl font-semibold">CUDA Sentinel — Operations Console</h1>
        </div>
        <div className="flex gap-3">
          <Button variant="outline" onClick={() => window.location.reload()}>
            <RefreshCw className="w-4 h-4 mr-2" /> Refresh
          </Button>
          <Button>
            <PlayCircle className="w-4 h-4 mr-2" /> Run Sanity Check
          </Button>
        </div>
      </div>

      {/* Services Grid */}
      <div className="grid md:grid-cols-3 gap-4">
        {services.map(s => (
          <Card key={s.id} className="shadow-sm">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Cpu className="w-4 h-4" />
                  <div className="font-medium">{s.name}</div>
                </div>
                <StatusBadge status={s.status} />
              </div>
              <div className="text-sm text-slate-600 mt-2">v{s.version} · {s.host} · uptime {s.uptime}</div>
              <div className="mt-3">
                <Progress value={s.status === "healthy" ? 100 : s.status === "degraded" ? 65 : 20} />
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* GPU Utilization Chart */}
      <Card className="shadow-sm">
        <CardContent className="p-4">
          <div className="flex items-center gap-2 mb-2"><Workflow className="w-4 h-4" /><div className="font-medium">GPU Utilization — gpu-host-01</div></div>
          <div className="h-52">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={gpuSeries}>
                <defs>
                  <linearGradient id="util" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#8884d8" stopOpacity={0.6}/>
                    <stop offset="95%" stopColor="#8884d8" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="mem" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#82ca9d" stopOpacity={0.6}/>
                    <stop offset="95%" stopColor="#82ca9d" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <XAxis dataKey="t" hide/>
                <YAxis hide/>
                <Tooltip />
                <Area type="monotone" dataKey="util" stroke="#8884d8" fillOpacity={1} fill="url(#util)" name="Util %" />
                <Area type="monotone" dataKey="mem" stroke="#82ca9d" fillOpacity={1} fill="url(#mem)" name="Mem %" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>

      {/* Events & Proposals */}
      <div className="grid md:grid-cols-2 gap-4">
        <Card className="shadow-sm">
          <CardContent className="p-4 space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2"><AlertTriangle className="w-4 h-4" /><div className="font-medium">Recent Events</div></div>
              <Input placeholder="Filter (type/severity/text)" value={filter} onChange={e => setFilter(e.target.value)} className="max-w-xs"/>
            </div>
            <div className="divide-y">
              {filteredEvents.map(e => (
                <div key={e.id} className="py-3">
                  <div className="flex items-center justify-between">
                    <div className="font-medium"><SevDot sev={e.severity}/> {e.type}</div>
                    <div className="text-xs text-slate-500">{e.time}</div>
                  </div>
                  <div className="text-sm text-slate-700">{e.summary}</div>
                  <div className="text-xs text-slate-500">{e.host} · GPU {e.gpu}</div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardContent className="p-4 space-y-3">
            <div className="flex items-center gap-2"><CheckCircle2 className="w-4 h-4" /><div className="font-medium">Executable Fixes</div></div>
            <div className="space-y-3">
              {proposals.map(p => (
                <div key={p.id} className="border rounded-xl p-3">
                  <div className="flex items-center justify-between">
                    <div className="font-medium">{p.title}</div>
                    <Badge variant="secondary" className="capitalize">{p.status}</Badge>
                  </div>
                  <div className="text-sm text-slate-700 mt-1">{p.rationale}</div>
                  <div className="text-xs text-slate-500 mt-1">Impact: {p.impact}</div>
                  <div className="text-xs mt-2">
                    <div className="text-slate-500">Steps:</div>
                    <ol className="list-decimal ml-5 space-y-1">
                      {p.steps.map((s: string, i: number) => <li key={i} className="font-mono text-[12px]">{s}</li>)}
                    </ol>
                  </div>
                  <div className="flex items-center gap-2 mt-3">
                    <Button size="sm" onClick={() => applyFix(p.id)} disabled={p.status !== "ready"}>Apply</Button>
                    <Button size="sm" variant="outline">Dry Run</Button>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="text-xs text-slate-500">Demo UI · Replace with live data from /v1/services, /v1/events, /v1/proposals</div>
    </div>
  );
}
