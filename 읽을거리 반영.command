#!/bin/zsh
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

echo "읽을거리 업데이트를 시작합니다."
echo

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "python3를 찾지 못했습니다. macOS에 Python 3가 설치되어 있는지 확인해주세요."
  echo
  read -k 1 "?아무 키나 누르면 종료합니다."
  exit 1
fi

"$PYTHON_BIN" "$SCRIPT_DIR/tools/update_readings_index.py"
STATUS=$?

echo
if [ "$STATUS" -eq 0 ]; then
  echo "작업이 완료되었습니다."
else
  echo "작업이 중단되었습니다. 위 메시지를 확인해주세요."
fi

echo
read -k 1 "?아무 키나 누르면 종료합니다."
exit "$STATUS"
