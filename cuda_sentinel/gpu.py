import subprocess
from pydantic import BaseModel

class GPUInfo(BaseModel):
    index: int
    name: str
    driver: str
    memory_used_mb: int | None = None
    memory_total_mb: int | None = None
    utilization_percent: int | None = None
    status: str = "unknown"

def inventory() -> list[GPUInfo]:
    command = ["nvidia-smi", "--query-gpu=index,name,driver_version,memory.used,memory.total,utilization.gpu", "--format=csv,noheader,nounits"]
    try:
        result = subprocess.run(command, check=False, capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return []
    if result.returncode != 0:
        return []
    gpus: list[GPUInfo] = []
    for line in result.stdout.splitlines():
        fields = [field.strip() for field in line.split(",")]
        if len(fields) != 6:
            continue
        try:
            gpus.append(GPUInfo(index=int(fields[0]), name=fields[1], driver=fields[2], memory_used_mb=int(fields[3]), memory_total_mb=int(fields[4]), utilization_percent=int(fields[5]), status="healthy"))
        except ValueError:
            continue
    return gpus
