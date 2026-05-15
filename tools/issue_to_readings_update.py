#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


DATA_MARKER = "## 8. 이번 반영 데이터"
DATE_PATTERN = re.compile(r"^\d{4}년\s+\d{1,2}월\s+\d{1,2}일$")
URL_PATTERN = re.compile(r"^https?://\S+$")


class SubmissionError(Exception):
    pass


def extract_issue_form_fields(body: str) -> dict[str, str]:
    fields: dict[str, list[str]] = {}
    current_label: str | None = None

    for line in body.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if line.startswith("### "):
            current_label = line[4:].strip()
            fields[current_label] = []
            continue
        if current_label is not None:
            fields[current_label].append(line)

    return {key: "\n".join(value).strip() for key, value in fields.items()}


def clean_multiline(value: str) -> list[str]:
    lines = []
    for raw_line in value.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("- "):
            line = line[2:].strip()
        lines.append(line)
    return lines


def normalize_attachments(value: str) -> str:
    if value.strip() == "없음":
        return "없음"

    items = []
    for line in clean_multiline(value):
        if line.startswith("* "):
            line = line[2:].strip()
        pair_match = re.match(r"^(.+?)\s*\|\s*(https?://\S+)$", line)
        if pair_match:
            line = f"{pair_match.group(1).strip()}({pair_match.group(2).strip()})"
        if not re.match(r"^.+?\(https?://[^\s)]+\)$", line):
            raise SubmissionError(f"첨부 형식이 올바르지 않습니다: {line}")
        items.append(f"* {line}")

    if not items:
        return "없음"
    return " | ".join(items)


def build_markdown(fields: dict[str, str]) -> str:
    required = ["날짜", "기관", "등록자", "제목", "주요 내용", "첨부", "링크"]
    missing = [field for field in required if not fields.get(field)]
    if missing:
        raise SubmissionError(f"필수 입력값이 없습니다: {', '.join(missing)}")

    date = fields["날짜"].strip()
    agency = fields["기관"].strip()
    submitter = fields["등록자"].strip()
    title = fields["제목"].strip()
    link = fields["링크"].strip()
    details = clean_multiline(fields["주요 내용"])
    attachments = normalize_attachments(fields["첨부"])

    if not DATE_PATTERN.match(date):
        raise SubmissionError("날짜는 `YYYY년 M월 D일` 형식이어야 합니다.")
    if not URL_PATTERN.match(link):
        raise SubmissionError("링크는 http 또는 https로 시작해야 합니다.")
    if not details:
        details = ["없음"]

    lines = [
        "# 읽을거리 업데이트 작업 지침",
        "",
        DATA_MARKER,
        "",
        f"# 날짜: {date}",
        "## 읽을거리 내용",
        "",
        "---",
        "",
        f"- 기관: {agency}",
        f"- 제목: {title}",
        f"- 등록자: {submitter}",
    ]

    if len(details) == 1 and details[0] == "없음":
        lines.append("- 주요 내용: 없음")
    else:
        lines.append("- 주요 내용:")
        lines.extend(f"  - {item}" for item in details if item != "없음")

    lines.extend([
        f"- 첨부: {attachments}",
        f"- 링크: {link}",
        "",
    ])
    return "\n".join(lines)


def append_archive(archive_path: Path, issue_number: int, issue_url: str, markdown: str) -> None:
    archive_path.parent.mkdir(parents=True, exist_ok=True)
    existing = archive_path.read_text(encoding="utf-8") if archive_path.exists() else "# 읽을거리 제출기록\n"
    block = [
        "",
        f"## Issue #{issue_number}",
        "",
        issue_url,
        "",
        "```md",
        markdown,
        "```",
        "",
    ]
    archive_path.write_text(existing.rstrip() + "\n" + "\n".join(block), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="GitHub Issue Form 제출 내용을 읽을거리 업데이트 markdown으로 변환합니다.")
    parser.add_argument("--event", type=Path, required=True, help="GitHub event JSON path")
    parser.add_argument("--output", type=Path, required=True, help="생성할 markdown 파일")
    parser.add_argument("--archive", type=Path, required=True, help="제출 원본 기록 파일")
    args = parser.parse_args()

    event = json.loads(args.event.read_text(encoding="utf-8"))
    issue = event.get("issue", {})
    fields = extract_issue_form_fields(issue.get("body", ""))
    markdown = build_markdown(fields)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(markdown, encoding="utf-8")
    append_archive(args.archive, issue.get("number", 0), issue.get("html_url", ""), markdown)
    print(f"Created {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
