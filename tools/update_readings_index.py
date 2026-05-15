#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import datetime as dt
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_MARKDOWN = ROOT / "읽을거리 업데이트.md"
DEFAULT_HTML = ROOT / "index.html"
RAW_TEXT_PATTERN = re.compile(r"const RAW_TEXT_BASE64 = '([^']+)';")
DATE_HEADER_PATTERN = re.compile(r"^# 날짜:\s*(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일\s*$")
FIELD_PATTERN = re.compile(r"^- (기관|제목|등록자|주요 내용|첨부|링크):\s*(.*)$")
SECTION_HEADER_PATTERN = re.compile(
    r"---------------\s+(\d{4}년\s+\d{1,2}월\s+\d{1,2}일(?:\s+[가-힣]+)?)\s+---------------"
)

AGENCY_ALIASES = {
    "KIEP": "대외경제정책연구원",
    "대외경제정책연구원": "대외경제정책연구원",
    "통계청": "국가데이터처",
    "국가데이터처": "국가데이터처",
    "하나금융연구소": "하나금융경영연구소",
    "하나금융경영연구소": "하나금융경영연구소",
    "한국금융연구원]": "한국금융연구원",
    "한국금융연구원": "한국금융연구원",
    "KITA": "한국무역협회",
    "한국무역협회": "한국무역협회",
    "KDI": "한국개발연구원",
    "한국개발연구원": "한국개발연구원",
    "뉴스 기사": "언론기사",
    "중소기업중앙회": "중기중앙회",
    "중기중앙회": "중기중앙회",
    "기획재정부": "재정경제부",
    "재정경제부": "재정경제부",
}

WEEKDAYS_KO = ["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"]


class UpdateError(Exception):
    pass


@dataclass
class Attachment:
    label: str
    url: str


@dataclass
class Entry:
    agency: str
    title: str
    details: list[str]
    attachments: list[Attachment]
    link: str
    submitter: str = ""


@dataclass
class DateSection:
    year: int
    month: int
    day: int
    entries: list[Entry]

    @property
    def date(self) -> dt.date:
        return dt.date(self.year, self.month, self.day)

    @property
    def label(self) -> str:
        return f"{self.year}년 {self.month}월 {self.day}일"

    @property
    def section_label(self) -> str:
        weekday = WEEKDAYS_KO[self.date.weekday()]
        return f"{self.label} {weekday}"

    @property
    def message_title(self) -> str:
        return f"<{self.month}.{self.day}일 읽을거리: 주요 정부부처 및 외부 연구기관 발간자료 >"


def normalize_agency_name(value: str) -> str:
    cleaned = re.sub(r"\s+", " ", value.replace("[", "").replace("]", "")).strip()
    return AGENCY_ALIASES.get(cleaned, cleaned)


def parse_attachment_chunk(chunk: str) -> Attachment:
    cleaned = chunk.strip()
    if cleaned.startswith("* "):
        cleaned = cleaned[2:].strip()

    match = re.match(r"(.+?)\((https?://[^\s)]+)\)\s*$", cleaned)
    if not match:
        raise UpdateError(f"첨부 형식을 해석할 수 없습니다: {chunk}")

    label = match.group(1).strip()
    url = match.group(2).strip()
    if not label or not url:
        raise UpdateError(f"첨부 값이 비어 있습니다: {chunk}")
    return Attachment(label=label, url=url)


def parse_markdown_sections(markdown_text: str) -> list[DateSection]:
    lines = markdown_text.replace("\ufeff", "").replace("\r\n", "\n").replace("\r", "\n").split("\n")
    sections: list[DateSection] = []
    current: DateSection | None = None
    current_entry: dict[str, object] | None = None
    in_data_area = False
    active_multiline_field: str | None = None

    def finalize_entry() -> None:
        nonlocal current_entry, active_multiline_field
        if current_entry is None:
            return

        required_fields = ("기관", "제목", "주요 내용", "첨부", "링크")
        missing = [name for name in required_fields if name not in current_entry]
        if missing:
            raise UpdateError(f"항목 필드가 누락되었습니다: {', '.join(missing)}")

        agency = str(current_entry.get("기관", "")).strip()
        title = str(current_entry.get("제목", "")).strip()
        submitter = str(current_entry.get("등록자", "")).strip()
        details = list(current_entry.get("주요 내용", []))
        attachments_raw = str(current_entry.get("첨부", "")).strip()
        link = str(current_entry.get("링크", "")).strip()

        if not agency or not title or not attachments_raw:
            raise UpdateError(f"항목 값이 비어 있습니다: {title or agency or '제목 없는 항목'}")

        if link == "없음" or not link:
            raise UpdateError(f"링크는 반드시 필요합니다: {title or agency}")

        attachments = [] if attachments_raw == "없음" else [
            parse_attachment_chunk(piece) for piece in attachments_raw.split(" | ")
        ]
        normalized_details = [] if details == ["없음"] else [line.strip() for line in details if line.strip()]

        entry = Entry(
            agency=normalize_agency_name(agency),
            title=title,
            details=normalized_details,
            attachments=attachments,
            link=link,
            submitter=submitter,
        )
        if current is None:
            raise UpdateError("날짜 섹션 없이 읽을거리 항목이 발견되었습니다.")
        current.entries.append(entry)
        current_entry = None
        active_multiline_field = None

    def finalize_section() -> None:
        nonlocal current
        finalize_entry()
        if current is not None:
            if not current.entries:
                raise UpdateError(f"날짜 섹션에 항목이 없습니다: {current.label}")
            sections.append(current)
            current = None

    for raw_line in lines:
        line = raw_line.rstrip()

        if not in_data_area:
            if line.strip() == "## 8. 이번 반영 데이터":
                in_data_area = True
            continue

        date_match = DATE_HEADER_PATTERN.match(line.strip())
        if date_match:
            finalize_section()
            year, month, day = map(int, date_match.groups())
            current = DateSection(year=year, month=month, day=day, entries=[])
            continue

        if line.strip() == "---":
            finalize_entry()
            current_entry = {"주요 내용": []}
            active_multiline_field = None
            continue

        if current_entry is None:
            continue

        field_match = FIELD_PATTERN.match(line.strip())
        if field_match:
            field_name, raw_value = field_match.groups()
            if field_name == "주요 내용":
                active_multiline_field = "주요 내용"
                current_entry[field_name] = [] if raw_value in ("", "없음") else [raw_value]
            else:
                current_entry[field_name] = raw_value
                active_multiline_field = None
            continue

        if active_multiline_field == "주요 내용":
            detail_match = re.match(r"^\s{2}-\s+(.+)$", line)
            if detail_match:
                details = current_entry.setdefault("주요 내용", [])
                if not isinstance(details, list):
                    raise UpdateError("주요 내용 형식이 잘못되었습니다.")
                details.append(detail_match.group(1).strip())
                continue

    finalize_section()

    if not sections:
        raise UpdateError("반영할 날짜 데이터를 찾지 못했습니다. `## 8. 이번 반영 데이터` 아래 형식을 확인해주세요.")

    return sections


def read_raw_text_from_html(html_text: str) -> str:
    match = RAW_TEXT_PATTERN.search(html_text)
    if not match:
        raise UpdateError("index.html에서 RAW_TEXT_BASE64를 찾지 못했습니다.")
    return base64.b64decode(match.group(1)).decode("utf-8")


def collect_existing_labels(raw_text: str) -> set[str]:
    labels = set()
    for match in SECTION_HEADER_PATTERN.finditer(raw_text):
        label = match.group(1)
        simple = re.match(r"(\d{4}년\s+\d{1,2}월\s+\d{1,2}일)", label)
        if simple:
            labels.add(simple.group(1))
    return labels


def collect_existing_sections(raw_text: str) -> dict[str, tuple[int, int]]:
    matches = list(SECTION_HEADER_PATTERN.finditer(raw_text))
    sections: dict[str, tuple[int, int]] = {}
    for index, match in enumerate(matches):
        simple = re.match(r"(\d{4}년\s+\d{1,2}월\s+\d{1,2}일)", match.group(1))
        if not simple:
            continue
        start = match.start()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(raw_text)
        sections[simple.group(1)] = (start, end)
    return sections


def build_section_text(section: DateSection) -> str:
    blocks: list[str] = [
        f"--------------- {section.section_label} ---------------",
        f"[정훈] [오전 9:00] {section.message_title}",
        "",
    ]

    blocks.extend(build_entry_blocks(section))

    return "\r\n".join(blocks).rstrip()


def build_entry_blocks(section: DateSection) -> list[str]:
    blocks: list[str] = []
    for index, entry in enumerate(section.entries):
        blocks.append(f"[{entry.agency}]")
        blocks.append(entry.title)
        if entry.submitter:
            blocks.append(f"등록자: {entry.submitter}")
        for detail in entry.details:
            blocks.append(f"- {detail}")
        for attachment in entry.attachments:
            blocks.append(f"* [첨부: {attachment.label}]({attachment.url})")
        blocks.append(f"({entry.link})")
        if index != len(section.entries) - 1:
            blocks.append("")

    return blocks


def build_entries_text(section: DateSection) -> str:
    return "\r\n".join(build_entry_blocks(section)).rstrip()


def append_section_entries(raw_text: str, start: int, end: int, section: DateSection) -> str:
    existing_text = raw_text[start:end].rstrip()
    new_entries = []
    for entry in section.entries:
        if entry.link in existing_text or entry.title in existing_text:
            continue
        single_section = DateSection(section.year, section.month, section.day, [entry])
        new_entries.append(build_entries_text(single_section))

    if not new_entries:
        return raw_text

    replacement = existing_text + "\r\n\r\n" + "\r\n\r\n".join(new_entries)
    if end < len(raw_text):
        replacement += "\r\n\r\n"
    return raw_text[:start] + replacement + raw_text[end:]


def update_html(html_text: str, new_raw_text: str) -> str:
    new_base64 = base64.b64encode(new_raw_text.encode("utf-8")).decode("ascii")
    return RAW_TEXT_PATTERN.sub(f"const RAW_TEXT_BASE64 = '{new_base64}';", html_text, count=1)


def create_backup(html_path: Path, html_text: str) -> Path:
    backup_dir = html_path.parent / "backup" / "index_backups"
    backup_dir.mkdir(parents=True, exist_ok=True)
    timestamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = backup_dir / f"index_{timestamp}.html"
    backup_path.write_text(html_text, encoding="utf-8")
    return backup_path


def run(markdown_path: Path, html_path: Path, dry_run: bool, append_existing: bool) -> int:
    markdown_text = markdown_path.read_text(encoding="utf-8-sig")
    sections = parse_markdown_sections(markdown_text)

    html_text = html_path.read_text(encoding="utf-8-sig")
    raw_text = read_raw_text_from_html(html_text)
    existing_sections = collect_existing_sections(raw_text)

    replacement_items: list[tuple[int, int, bool, str]] = []
    new_blocks: list[str] = []
    replaced_sections: list[DateSection] = []
    added_sections: list[DateSection] = []

    for section in sections:
        block = build_section_text(section)
        if section.label in existing_sections:
            start, end = existing_sections[section.label]
            if append_existing:
                replacement_items.append((start, end, end == len(raw_text), ""))
            else:
                replacement_items.append((start, end, end == len(raw_text), block))
            replaced_sections.append(section)
        else:
            new_blocks.append(block)
            added_sections.append(section)

    new_raw_text = raw_text
    for start, end, is_final, block in sorted(replacement_items, key=lambda item: item[0], reverse=True):
        if append_existing:
            section = next(
                item for item in sections
                if collect_existing_sections(raw_text).get(item.label) == (start, end)
            )
            new_raw_text = append_section_entries(new_raw_text, start, end, section)
        else:
            replacement = block.rstrip()
            if not is_final:
                replacement += "\r\n\r\n"
            new_raw_text = new_raw_text[:start] + replacement + new_raw_text[end:]

    new_raw_text = new_raw_text.rstrip()
    if new_blocks:
        separator = "\r\n\r\n" if new_raw_text else ""
        new_raw_text = new_raw_text + separator + "\r\n\r\n".join(new_blocks)
    new_raw_text += "\r\n"

    if dry_run:
        print("미리보기 모드입니다. 아래 날짜가 반영됩니다.")
        for section in replaced_sections:
            print(f"- 갱신: {section.section_label} / {len(section.entries)}건")
        for section in added_sections:
            print(f"- 추가: {section.section_label} / {len(section.entries)}건")
        return 0

    backup_path = create_backup(html_path, html_text)
    updated_html = update_html(html_text, new_raw_text)
    html_path.write_text(updated_html, encoding="utf-8")

    print("index.html 업데이트를 완료했습니다.")
    print(f"- 대상 HTML: {html_path}")
    print(f"- 백업 파일: {backup_path}")
    for section in replaced_sections:
        print(f"- 갱신 날짜: {section.section_label} / {len(section.entries)}건")
    for section in added_sections:
        print(f"- 추가 날짜: {section.section_label} / {len(section.entries)}건")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="`읽을거리 업데이트.md`를 읽어 index.html의 RAW_TEXT_BASE64 데이터를 갱신합니다."
    )
    parser.add_argument("--markdown", type=Path, default=DEFAULT_MARKDOWN, help="업데이트 원본 markdown 경로")
    parser.add_argument("--html", type=Path, default=DEFAULT_HTML, help="업데이트 대상 index.html 경로")
    parser.add_argument("--dry-run", action="store_true", help="실제 파일 변경 없이 추가 대상만 확인")
    parser.add_argument("--append-existing", action="store_true", help="이미 있는 날짜 섹션은 교체하지 않고 새 항목만 뒤에 추가")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    try:
        return run(args.markdown.resolve(), args.html.resolve(), args.dry_run, args.append_existing)
    except FileNotFoundError as exc:
        print(f"파일을 찾지 못했습니다: {exc.filename}", file=sys.stderr)
        return 1
    except UpdateError as exc:
        print(f"업데이트 중단: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
