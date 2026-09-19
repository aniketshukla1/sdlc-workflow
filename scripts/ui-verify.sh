#!/usr/bin/env bash
# One-command local verification before UI testing: boots compose, waits for health, prints URLs + checklist.
# Usage: ./scripts/ui-verify.sh
set -euo pipefail

echo "→ docker compose up -d --build"
docker compose up -d --build -q 2>/dev/null || docker compose up -d --build

echo "→ waiting for backend /healthz (max 90s)"
for _ in $(seq 1 45); do
  curl -sf http://localhost:8000/healthz >/dev/null 2>&1 && { echo "OK backend http://localhost:8000/healthz"; break; }
  sleep 2
  [[ "${_}" == "45" ]] && { echo "FAIL backend not healthy"; docker compose ps; exit 1; }
done

echo "→ frontend (if configured): http://localhost:3000 (or your compose port)"
curl -s -o /dev/null -w "frontend HTTP %{http_code}\n" http://localhost:3000 || true

echo ""
echo "✓ App is up. Test in UI now (STILL LOCAL — nothing pushed to origin):"
echo "  Backend:  http://localhost:8000/docs"
echo "  Frontend: http://localhost:3000"
echo "  1. Follow MR 'How to test — UI' steps  2. Try one invalid input  3. Check console errors"
echo "  4. Keyboard-only tab pass  5. Confirm at 1280px + 390px widths"
echo "  Pass → ./scripts/publish.sh (first push). Fail → back to /build (still local)."
echo "  Teardown: docker compose down"
