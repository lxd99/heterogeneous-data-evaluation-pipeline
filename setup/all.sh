#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
bash setup/clone_repos.sh
bash setup/create_envs.sh
bash setup/prepare_data.sh
bash verify_setup.sh
