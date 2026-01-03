#!/usr/bin/env bash
# Use bash from env so it works across Linux/macOS
set -euo pipefail
# -e: exit on any command failure
# -u: treat unset variables as errors
# -o pipefail: fail a pipeline if any command inside it fails

# Absolute directory where this script lives (not where you run it from)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-detect project root:
# - If the script is placed in the repo root, PROJECT_ROOT is SCRIPT_DIR
# - If the script is placed in repo_root/scripts, PROJECT_ROOT becomes SCRIPT_DIR/..
PROJECT_ROOT="$SCRIPT_DIR"
if [[ ! -d "$PROJECT_ROOT/init" && -d "$SCRIPT_DIR/../init" ]]; then
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# Folder containing the SQL init files
INIT_DIR="$PROJECT_ROOT/init"
# Optional .env file to load DATABASE_URL_NEON from
ENV_FILE="$PROJECT_ROOT/.env"

# Print an error message and exit
die() { echo "ERROR: $*" >&2; exit 1; }

# Ensure the connection string enforces TLS.
# If sslmode is missing, append sslmode=require to the URL.
ensure_sslmode() {
  local url="$1"

  # If URL already has sslmode, do nothing
  if [[ "$url" == *"sslmode="* ]]; then
    echo "$url"
    return
  fi

  # If URL already has query params, append with '&', otherwise start with '?'
  if [[ "$url" == *"?"* ]]; then
    echo "${url}&sslmode=require"
  else
    echo "${url}?sslmode=require"
  fi
}

# Load environment variables from .env if present.
# NOTE: This uses "source" which expects the .env to be shell-compatible.
# If your .env contains special characters (e.g., unquoted '&'), it can break.
load_env_if_present() {
  if [[ -f "$ENV_FILE" ]]; then
    echo "Loading env from: $ENV_FILE"

    # set -a exports all variables defined by the sourced file
    set -a
    # shellcheck disable=SC1090
    # Source only non-comment, non-empty lines
    source <(grep -vE '^\s*#' "$ENV_FILE" | grep -vE '^\s*$')
    set +a
  else
    echo "No .env found at $ENV_FILE (skipping)."
  fi
}

# Ensure psql client is installed (needed to run SQL against Neon)
command -v psql >/dev/null 2>&1 || die "psql not found. Install PostgreSQL client tools (psql) or run via Docker client image."

# Ensure init directory exists
[[ -d "$INIT_DIR" ]] || die "Init folder not found: $INIT_DIR"

# Load .env (so DATABASE_URL_NEON can come from there)
load_env_if_present

# Read DATABASE_URL_NEON from environment, fallback to POSTGRES_URL if used
DATABASE_URL_NEON="${DATABASE_URL_NEON:-${POSTGRES_URL:-}}"
[[ -n "${DATABASE_URL_NEON:-}" ]] || die "DATABASE_URL_NEON not set (and POSTGRES_URL not set). Put it in .env or export it."

# Force sslmode=require if missing
DATABASE_URL_NEON="$(ensure_sslmode "$DATABASE_URL_NEON")"

# Build an ordered list of .sql files in INIT_DIR, excluding anything matching *_dev_*
# - find: collects files
# - sort: ensures deterministic order (01_..., 02_..., etc.)
mapfile -t SQL_FILES < <(
  find "$INIT_DIR" -maxdepth 1 -type f -name "*.sql" ! -name "*_dev_*" -print \
  | LC_ALL=C sort
)

# Fail if there are no SQL files to run
[[ "${#SQL_FILES[@]}" -gt 0 ]] || die "No .sql files found in $INIT_DIR (after filtering *_dev_*)."

# Print what will be executed
echo "Project root: $PROJECT_ROOT"
echo "Using INIT_DIR: $INIT_DIR"
echo "Files to execute (skipping *_dev_*):"
for f in "${SQL_FILES[@]}"; do
  echo "  - $(basename "$f")"
done
echo

# Create a temporary "master SQL" file that includes all the SQL scripts
TMP_SQL="$(mktemp)"

# Always delete the temp file on exit (success or failure)
cleanup() { rm -f "$TMP_SQL"; }
trap cleanup EXIT

# Generate the master SQL file:
# - Stop immediately on any SQL error
# - Wrap everything in a transaction so it all succeeds or all rolls back
{
  echo "\\set ON_ERROR_STOP on"
  for f in "${SQL_FILES[@]}"; do
    echo "\\echo ===== Running $(basename "$f") ====="
    echo "\\i $f"
  done
} > "$TMP_SQL"

# Execute the generated master SQL file against Neon
echo "Running initialization against Neon..."

#-P pager=off -> disables less (it doesn't wait).
#-X -> ignores your ~/.psqlrc (sometimes pager/formatting is enabled there and causes unexpected issues).

psql "$DATABASE_URL_NEON" -X -P pager=off -v ON_ERROR_STOP=1 -f "$TMP_SQL"

echo
echo "Done. Neon DB initialized successfully."
