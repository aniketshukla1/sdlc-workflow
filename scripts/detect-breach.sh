#!/usr/bin/env bash
# Deterministic breach detection — no model here. Mean + std over a rolling window
# (Western Electric simplified). Version-controlled + unit-tested.
# Usage: ./scripts/detect-breach.sh <metric-values-file>  # exits 0=log, 1=diagnose, 2=propose
set -euo pipefail
FILE="${1:-/dev/stdin}"
python3 - "$FILE" <<'PY'
import sys, statistics
vals=[float(l.strip()) for l in open(sys.argv[1]) if l.strip()]
assert len(vals) >= 10, "need >=10 samples for a baseline"
base=vals[:-1]; cur=vals[-1]
mean=statistics.mean(base); sd=statistics.pstdev(base) or 1e-9
z=(cur-mean)/sd
print(f"mean={mean:.4f} sd={sd:.4f} cur={cur:.4f} z={z:.2f}")
sys.exit(2 if abs(z) >= 3 else (1 if abs(z) >= 2 else 0))
PY
