# Bộ skill `/tc-review` — Đối chiếu Test Case ↔ FSD (coverage gap review)

> Gói đóng sẵn để gửi/cài sang project khác. Skill `/tc-review` đọc **FSD (source of truth)** + **bộ test case có sẵn**, trích mọi đơn vị kiểm thử từ FSD rồi đo **độ phủ của test case so với FSD** — chỉ ra chỗ **thiếu / yếu / thừa** và đề xuất test case bổ sung.

Mục tiêu: trả lời câu hỏi **"test case đã cover hết FSD chưa?"** một cách có hệ thống, truy được về FSD, không bịa.

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

**Luồng 7 pha (report-first, L1 trước khi ghi file):**

1. **A** — Đọc FSD + test case (Outline qua MCP, hoặc file local CSV/MD/XLSX).
2. **B** — Trích đơn vị kiểm thử từ FSD, gán ID: `FR` / `FLOW` / `BR` / `VAL` / `ERR` / `ENUM` / `NFR`.
3. **C** — Map test case vào từng đơn vị (map suy luận đánh dấu `?`).
4. **D** — Chấm gap: ✅ Covered / ⚠️ Yếu / ❌ Thiếu + 🔶 TC thừa, kèm severity.
5. **E** — In ma trận coverage + % ra chat (report-first).
6. **F** — Ghi `docs/test-coverage/{feature}.md` (xác nhận L1; `--report-only` để bỏ qua).
7. **G** — Đề xuất test case bổ sung + recommend next.

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
