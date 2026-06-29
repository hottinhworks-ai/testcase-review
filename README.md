# `/tc-review` — Test Case Coverage Review against FSD

> A Claude Code skill that checks whether an existing **test case** set actually covers its **FSD** — finding what's missing, weak, or out of scope.
> Skill cho Claude Code: kiểm tra **bộ test case** đã cover hết **FSD** chưa — chỉ ra chỗ thiếu, yếu, hoặc ngoài phạm vi.

---

## 🇬🇧 English

### The pain point

QA writes test cases from an FSD, but **nobody really knows if the test set covers the whole spec**. Checking coverage by hand — eyeballing a test spreadsheet against a long FSD — is slow, inconsistent, and easy to get wrong. The usual blind spots:

- Defined **error codes / business rules / validations** that no test exercises.
- Functions tested only on the **happy path**, with no negative or boundary cases.
- **Out-of-scope** test cases that test behaviour the FSD never specified (or that reveal the FSD is missing a spec).
- No reliable **coverage %**, and no traceable list of gaps to act on.

### Purpose

`/tc-review` automatically compares an **existing test case set** against its **FSD (the source of truth)** and answers *"have the test cases covered the whole FSD?"* — producing a coverage matrix, a prioritized gap list (**missing / weak / orphan**), and concrete **test cases to add**. Everything is traceable back to the FSD; it never invents gaps for parts the FSD doesn't specify.

### How it works

A 7-phase flow (report-first — prints to chat, asks before writing files):

1. **Ingest** — read the FSD + test cases (from Outline via MCP, or local `CSV` / `MD` / `XLSX`).
2. **Extract coverage units** from the FSD with stable IDs: functional requirements, flow steps, business rules, field validations, error codes, enumerations, testable NFRs.
3. **Map** each test case to those units (inferred mappings are flagged `?` for QA to confirm).
4. **Score gaps** per unit — ✅ Covered / ⚠️ Weak / ❌ Missing — plus 🔶 orphan test cases, with severity.
5. **Report** the coverage matrix + % to chat.
6. **Write** the full report to `docs/test-coverage/{feature}.md` (after approval).
7. **Suggest** the test cases to add, prioritized by severity.

**Core principles:** the FSD is the source of truth; never fabricate gaps for unspecified parts (flag them as Open Questions instead); *covered ≠ well-tested* — coverage is counted by branch (happy / negative / boundary), so one happy-path test for a rule with error branches is still **Weak**.

---

## 🇻🇳 Tiếng Việt

### Vấn đề (pain point)

QA viết test case từ FSD, nhưng **không ai chắc bộ test đã cover hết đặc tả chưa**. Kiểm tra độ phủ thủ công — dò bảng test case đối chiếu một FSD dài — vừa chậm, vừa thiếu nhất quán, dễ sót. Các điểm mù thường gặp:

- **Mã lỗi / business rule / validation** đã định nghĩa nhưng không có test nào chạm tới.
- Chức năng chỉ test **happy path**, thiếu case negative/biên.
- Test case **ngoài phạm vi** — kiểm thử hành vi FSD không hề spec (hoặc lộ ra FSD đang thiếu spec).
- Không có **% độ phủ** đáng tin và không có danh sách gap truy được để xử lý.

### Mục đích

`/tc-review` tự động đối chiếu **bộ test case có sẵn** với **FSD (source of truth)** và trả lời câu hỏi *"test case đã cover hết FSD chưa?"* — sinh ma trận coverage, danh sách gap có ưu tiên (**thiếu / yếu / thừa**), và **test case cần bổ sung** cụ thể. Mọi nhận định truy được về FSD; không bịa gap cho phần FSD không spec.

### Cách hoạt động

Luồng 7 pha (report-first — in ra chat, xác nhận trước khi ghi file):

1. **Đọc nguồn** — FSD + test case (từ Outline qua MCP, hoặc file local `CSV` / `MD` / `XLSX`).
2. **Trích đơn vị kiểm thử** từ FSD kèm ID ổn định: functional requirement, bước luồng, business rule, field validation, mã lỗi, enumeration, NFR kiểm được.
3. **Map** từng test case vào các đơn vị đó (map suy luận đánh dấu `?` để QA xác nhận).
4. **Chấm gap** mỗi đơn vị — ✅ Covered / ⚠️ Yếu / ❌ Thiếu — cùng 🔶 test case thừa (orphan), kèm severity.
5. **Báo cáo** ma trận coverage + % ra chat.
6. **Ghi** báo cáo đầy đủ vào `docs/test-coverage/{feature}.md` (sau khi duyệt).
7. **Đề xuất** test case cần bổ sung, ưu tiên theo severity.

**Nguyên tắc cốt lõi:** FSD là chuẩn; không bịa gap cho phần chưa spec (ghi Open Question); *covered ≠ test tốt* — đếm theo nhánh (happy / negative / boundary), nên 1 test happy-path cho rule có nhánh lỗi vẫn là **Yếu**.

---

## Gói này có gì

```
tc-review-skill/
├── README.md                       ← bạn đang đọc
└── claude-code/
    ├── .claude/
    │   ├── skills/tc-review/SKILL.md     ← skill chính
    │   └── rules/                        ← 5 rule skill phụ thuộc
    │       ├── ba-conventions.md
    │       ├── approval-gate.md
    │       ├── naming-conventions.md
    │       ├── review-format.md          (thang severity)
    │       └── changelog.md
    └── _templates/
        └── tc-coverage-report.md         ← khung báo cáo coverage
```

---

## Cài vào một workspace Claude Code

Từ thư mục gốc của gói, copy cây `claude-code/` vào gốc workspace đích:

```bash
cp -R claude-code/.claude/skills/tc-review   <workspace>/.claude/skills/
cp    claude-code/.claude/rules/*.md          <workspace>/.claude/rules/
cp    claude-code/_templates/tc-coverage-report.md  <workspace>/_templates/
```

> **5 rule trong `.claude/rules/`** đã được skill tham chiếu. Nếu workspace đích đã có bộ BA-KIT thì các rule này có thể đã tồn tại — giữ bản đang dùng, không cần đè. Nếu chưa có, bắt buộc copy đủ 5 file.

4 thành phần core phải có mặt:

| Thành phần | Đường dẫn trong workspace |
|---|---|
| Skill chính | `.claude/skills/tc-review/SKILL.md` |
| Template báo cáo | `_templates/tc-coverage-report.md` |
| Rule phụ thuộc | `.claude/rules/{ba-conventions,approval-gate,naming-conventions,review-format,changelog}.md` |
| Thư mục output | `docs/test-coverage/` (skill tự tạo khi ghi) |

---

## Dùng skill

```
/tc-review <fsd> <testcase>          # fsd + testcase = urlId/URL Outline HOẶC đường dẫn file local
/tc-review MiXI6vFmP8 "Test case/TC_Round2.xlsx"   # FSD trên Outline + test case Excel local
/tc-review --report-only             # chỉ in chat, không ghi file
/tc-review --out docs/test-coverage/payment.md     # đổi nơi ghi
```

Hoặc nói tự nhiên: *"review test case"*, *"test case cover hết FSD chưa"*, *"đối chiếu test case với FSD"*.

---

## Nguyên tắc cốt lõi (gài cứng trong skill)

- **FSD là chuẩn đối chiếu** — đo test case so với FSD, không bắt FSD theo test case.
- **KHÔNG bịa gap** — phần FSD trống / `<Hint>` / bị gạch → ghi Open Question, **loại khỏi mẫu số** coverage.
- **Covered ≠ test tốt** — 1 TC happy-path cho rule có nhánh lỗi vẫn là **Yếu**; đếm theo **nhánh** (happy / negative / boundary).
- **Map mơ hồ phải hiện `?`** — coverage % ghi rõ phần nào chắc, phần nào suy luận cần QA xác nhận.
- **Test case thừa** (không map FSD nào) → tín hiệu: ngoài phạm vi *hoặc* FSD thiếu spec → để người review quyết.
- **Xác minh trước khi báo "thiếu"** — grep lại nguồn test bằng từ khóa (mã lỗi, "trùng", "offline"…) để tránh báo gap sai.

---

## Đầu vào test case

- **Outline doc:** đọc qua MCP outline (như FSD).
- **File local `.csv` / `.md`:** đọc thẳng; parse cột chuẩn nếu có (`ID`, `Title`, `Precondition`, `Steps`, `Expected`, `Priority`, cột traceability `FSD ref`/`Requirement`/`UC`).
- **File local `.xlsx`:** **parse trực tiếp** (không cần export CSV). `.xlsx` là zip → skill giải nén bằng bsdtar, dựng bảng tra `sharedStrings.xml`, ghép vào từng `worksheets/sheetN.xml` (map qua `workbook.xml` + `.rels`), tái tạo hàng/cột bằng gawk. Nếu đường dẫn có dấu cách → copy ra path tạm không dấu cách trước. Chỉ khi parse lỗi mới cần CSV.

Chất lượng đối chiếu tốt nhất khi test case có **cột traceability** trỏ về requirement/UC của FSD; nếu không, skill suy luận theo expected/từ khóa và đánh dấu `?`.
