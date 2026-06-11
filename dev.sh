#!/bin/bash
# One command to start everything for development.
# Usage:  ./dev.sh
#         ./dev.sh --setup   (first time: installs deps + migrates DB)

FLUTTER=/Users/nitro/Documents/PROJECTS\ /srinishitha/Flutter/flutter/bin/flutter
ADMIN_DIR="$(dirname "$0")/manage/vachika-lekhini-admin"
ROOT_DIR="$(dirname "$0")"

# ── colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log() { echo -e "${GREEN}[dev]${NC} $1"; }
warn() { echo -e "${YELLOW}[dev]${NC} $1"; }

# ── first-time setup ──────────────────────────────────────────────────────────
if [[ "$1" == "--setup" ]]; then
  log "Installing admin dependencies..."
  cd "$ADMIN_DIR" && bun install

  log "Applying Prisma migrations..."
  bunx prisma migrate dev

  log "Seeding database (mantras, store items, admin user)..."
  bunx prisma db seed

  log "Setup complete. Run ./dev.sh to start."
  exit 0
fi

# ── start backend ─────────────────────────────────────────────────────────────
log "Starting SvelteKit backend on http://0.0.0.0:5173 ..."
cd "$ADMIN_DIR" && bun run dev &
BACKEND_PID=$!

# ── start Flutter ─────────────────────────────────────────────────────────────
log "Starting Flutter app (connects to backend automatically)..."
cd "$ROOT_DIR" && $FLUTTER run &
FLUTTER_PID=$!

log "Backend PID: $BACKEND_PID  |  Flutter PID: $FLUTTER_PID"
log "Press Ctrl+C to stop both."

# ── cleanup on exit ───────────────────────────────────────────────────────────
trap "log 'Stopping...'; kill $BACKEND_PID $FLUTTER_PID 2>/dev/null; exit" INT TERM

wait
