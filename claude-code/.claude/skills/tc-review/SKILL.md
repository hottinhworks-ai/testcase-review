---
name: tc-review
description: Use when user wants to review/đối chiếu TEST CASE với FSD — đọc FSD (source of truth) + bộ test case có sẵn rồi xác định test case đã cover hết FSD chưa (gap thiếu/yếu/thừa). Triggered by `/tc-review`, "review test case", "test case cover hết FSD chưa", "kiểm tra độ phủ test case", "đối chiếu test case với FSD". Đọc FSD + test case từ Outline hoặc file local; output ma trận coverage + gap vào docs/test-coverage/. KHÁC /userguide (viết hướng dẫn từ FSD) và /cr (review code diff).
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task
user-invocable: true
context: fork
argument-hint: "<fsd> <testcase> | --src outline|local | --out docs/test-coverage/{feature}.md | --report-only"
---

# /tc-review — Đối chiếu Test Case ↔ FSD (coverage gap review)

> Skill chạy `context: fork` (đọc FSD + bộ test case + trích đơn vị + map + suy luận). Main context giữ sạch.

## Goal

Đo **độ phủ của bộ test case so với FSD**. Skill đọc **FSD (source of truth)** + **test case có sẵn**, trích mọi **đơn vị kiểm thử** từ FSD (requirement / luồng / business rule / validation / mã lỗi / enum / NFR), map từng test case vào các đơn vị đó, rồi chỉ ra **chỗ chưa được test (gap)** theo 3 nhóm: **thiếu / yếu / thừa**. Kết quả là một **ma trận coverage + danh sách gap + đề xuất test case bổ sung**, in ra chat trước (report-first) rồi ghi `docs/test-coverage/{feature}.md` sau khi user duyệt.

Bản chất: từ "đã có FSD + test case" → "biết test case còn hở chỗ nào của FSD". Mọi nhận định **truy được về FSD** — không bịa "đáng lẽ phải test X" nếu FSD không nêu.

## Skill này khác gì các skill khác

| Skill | Hướng | Đầu vào | Khác biệt |
|-------|-------|---------|-----------|
| `/userguide` | FSD → hướng dẫn | FSD | Viết cẩm nang người vận hành |
| `/cr` | Review code | diff code | Soi chất lượng/bảo mật code |
| `/gap` | Traceability BA docs | docs/{feature} | Liên kết URD↔BRD↔SRS↔US |
| **`/tc-review`** | **Đối chiếu QA** | **FSD + test case** | **Đo độ phủ test case so với FSD, tìm gap** |

## Constraints

- **FSD là source of truth.** Đo độ phủ test case SO VỚI FSD. KHÔNG kết luận "FSD sai" vì thiếu test; ngược lại, test case không khớp FSD nào là **tín hiệu** (thừa/ngoài phạm vi hoặc FSD thiếu spec) → ghi để người review quyết, không tự sửa.
- **KHÔNG bịa.** FSD không nêu rõ rule/giá trị/ngưỡng/lỗi → KHÔNG tự chế đơn vị kiểm thử rồi báo "thiếu test". Đơn vị FSD mơ hồ/trống/`<Hint>`/bị gạch (struck-through) → **bỏ qua + ghi OQ**, không tạo đơn vị giả để phồng số liệu gap.
- **Trích đơn vị kiểm thử có hệ thống** (Pha B). Mỗi đơn vị FSD gán **ID ổn định** để truy vết (FR-01, FLOW-uc1.3, BR-02, VAL-fromdate, ERR-REP-003, ENUM-actiontype:Edit, NFR-01).
- **Map nhiều–nhiều.** 1 test case cover nhiều đơn vị; 1 đơn vị thường cần **nhiều** test case (happy + negative + boundary). Đừng đánh "Covered" chỉ vì có 1 TC happy-path cho một rule có nhánh lỗi.
- **Map mơ hồ phải đánh dấu `?`** — không tự tin map sai làm lệch coverage %. Ưu tiên traceability tường minh trong test case (cột "FSD ref"/"Requirement"); không có thì suy luận theo expected/từ khóa và đánh `?`.
- **Phân loại gap 3 nhóm + severity** (Pha D), severity theo `review-format.md` (CRITICAL/HIGH/MEDIUM/LOW → ở đây map BLOCKING≈CRITICAL).
- **Report-first.** Phần phân tích in ra chat trước (ma trận terse + gap). **L1 plan** trước khi Write file báo cáo. `--report-only` = chỉ in chat, không ghi file.
- **Read-only nguồn.** KHÔNG sửa FSD, KHÔNG sửa test case. Artifact duy nhất là báo cáo coverage.
- **Vietnamese-first.** Giữ ID/tên field/mã lỗi gốc; typography "Mục N" không dùng §; `→` chỉ trong bảng/flow.
- **Đọc được cả `.xlsx`.** `.csv`/`.md` đọc thẳng. `.xlsx` = file zip → **giải nén + parse trực tiếp** (xem Pha A.2), KHÔNG cần user export CSV trừ khi parse lỗi. Đường dẫn có dấu cách → copy sang đường dẫn tạm không dấu cách trước khi giải nén.

## Inputs

```
/tc-review <fsd> <testcase>     # fsd + testcase = urlId/URL Outline HOẶC đường dẫn file local
/tc-review                      # không arg → skill hỏi FSD + test case ở đâu
/tc-review --src outline        # ép coi nguồn là Outline
/tc-review --src local          # ép coi nguồn là file local
/tc-review --report-only        # chỉ in chat, KHÔNG ghi file
/tc-review --out docs/test-coverage/payment.md   # đổi nơi ghi báo cáo
```

- **Nhận diện nguồn tự động:** token khớp urlId Outline (vd `Lh5DJM2hBg`) hoặc URL `wiki.../doc/...` → đọc qua `mcp__outline__get_document`. Token là đường dẫn file (`*.md`/`*.csv`/`*.xlsx`) → đọc local. Cờ `--src` override khi nhập nhằng.
- Thiếu **fsd** hoặc **testcase** → hỏi rõ, KHÔNG tự đoán.
- FSD lớn (get_document trả >25k token, bị lưu ra file) → đọc theo lát cắt ký tự (`cut -c` / bsdtar) đến 100%, KHÔNG review khi chưa đọc hết.

## Context (dynamic)

Today: !`date +%Y-%m-%d`
Đã có report: !`ls docs/test-coverage/*.md 2>/dev/null | wc -l | tr -d ' '` file trong docs/test-coverage/

---

## Runtime flow

```
/tc-review <fsd> <testcase>
        │
        ▼
[Pha A] Resolve + ingest: đọc FSD (Outline/local) + test case (Outline/CSV/MD). In inventory.
        │
        ▼
[Pha B] Trích COVERAGE UNIT từ FSD → gán ID (FR/FLOW/BR/VAL/ERR/ENUM/NFR). Bỏ phần trống/Hint/struck.
        │
        ▼
[Pha C] Chuẩn hóa test case → map vào coverage unit (ưu tiên traceability tường minh; suy luận → đánh `?`).
        │
        ▼
[Pha D] Detect gap mỗi unit: ✅ Covered / ⚠️ Weak / ❌ Missing + severity. Tìm TC thừa (orphan).
        │
        ▼
[Pha E] IN BÁO CÁO ra chat (report-first): coverage % + ma trận terse + gap + orphan + OQ.
        │
        ▼
[Pha F] L1 plan → Write docs/test-coverage/{feature}.md (bỏ nếu --report-only).
        │
        ▼
[Pha G] Đề xuất test case bổ sung (per Missing/Weak) + recommend next.
```

## Approach (chi tiết từng pha)

### Pha A — Resolve & ingest

1. Resolve `fsd` và `testcase` về nguồn (Outline vs local) theo Inputs. Đọc nội dung đầy đủ.
2. **Test case từ CSV/MD:** parse các cột chuẩn nếu có — `ID`, `Title/Summary`, `Precondition`, `Steps`, `Expected`, `Priority`, và cột traceability (`FSD ref`/`Requirement`/`UC`). Cột tên khác → ánh xạ mềm.

   **Test case từ `.xlsx` (parse trực tiếp, không cần export CSV):** `.xlsx` là zip nén ô chữ trong XML. Quy trình:
   - Copy file sang đường dẫn tạm KHÔNG dấu cách (vd `/tmp/tc.xlsx`) rồi giải nén bằng bsdtar: `/c/Windows/System32/tar.exe -xf /tmp/tc.xlsx -C /tmp/_xlsx` (bsdtar đọc zip; `unzip` thường không có trên Git Bash).
   - Lấy tên sheet: `xl/workbook.xml` (`<sheet name=... r:id=...>`) → map r:id sang file qua `xl/_rels/workbook.xml.rels` (rIdN → `worksheets/sheetN.xml`).
   - Dựng bảng tra shared string từ `xl/sharedStrings.xml`: tách theo `<si>`, lấy text trong `<t>`, decode entity (`&amp; &lt; &gt; &quot; &#10;`). Dòng thứ (idx+1) = chuỗi index idx.
   - Tái tạo sheet: với mỗi `<row>`, mỗi `<c ... t="s"><v>IDX</v></c>` thay IDX bằng shared string; cell không `t="s"` lấy thẳng `<v>`. Dùng `gawk` `match()` để duyệt cell + giữ cột.
   - Hàng tiêu đề (Mã Case / Chức năng / Tóm tắt / Điều kiện / Bước / Kết quả mong đợi…) định nghĩa cột → đọc các hàng TC theo đó.
   - **Chỉ khi parse lỗi** (xlsx mã hóa, cấu trúc lạ) → mới yêu cầu user export CSV hoặc dán bảng.
3. In **bảng inventory** (chat): `FSD: {N} mục/section` · `Test case: {M} TC ({có/không} cột traceability)`. Thiếu nguồn → dừng hỏi.

### Pha B — Trích coverage unit từ FSD

4. Quét FSD, trích đơn vị kiểm thử theo bảng dưới, mỗi đơn vị **1 dòng + ID + 1 câu mô tả**:

   | Loại đơn vị | Nguồn trong FSD | ID format |
   |-------------|-----------------|-----------|
   | Functional Requirement | §"Function/Functional Requirements" | `FR-{NN}` |
   | Luồng chính / bước use case | Main Flow / User flow (mỗi bước có kết quả kiểm được) | `FLOW-{uc}.{step}` |
   | Business rule | cột "Business Rules" / mục Rule | `BR-{NN}` |
   | Field validation | "UI Screen & Validation" (mỗi field × rule bắt buộc/định dạng/khoảng) | `VAL-{field}` |
   | Mã lỗi / Exception | Error Matrix / Exception case | `ERR-{code}` / `EX-{NN}` |
   | Enumeration | entity types, action types, status, loại giao dịch… (mỗi giá trị) | `ENUM-{name}:{value}` |
   | NFR kiểm được | Performance/Security (có ngưỡng/điều kiện cụ thể) | `NFR-{NN}` |

5. **Bỏ phần không kiểm thử được** (mô tả kiến trúc, sơ đồ context, perspective). Phần **trống / `<Hint>` / struck-through** → KHÔNG tạo đơn vị, ghi 1 dòng OQ "phần X của FSD chưa có spec → không đo được coverage".

### Pha C — Chuẩn hóa test case + map

6. Chuẩn hóa mỗi TC: `id`, `mục tiêu`, `loại` (happy / negative / boundary — suy từ expected nếu không ghi rõ), `bước`, `expected`.
7. **Map TC → coverage unit:**
   - (a) **Traceability tường minh:** TC có cột FSD ref/Requirement/UC → map thẳng, đối chiếu xem ref có tồn tại trong đơn vị Pha B (ref sai/lạc → đánh dấu).
   - (b) **Suy luận:** không có cột ref → match theo expected/từ khóa/tên field/mã lỗi. Map suy luận **luôn kèm `?`** để người review xác nhận.
   - 1 TC map được nhiều unit thì ghi nhiều; ghi rõ TC đó test **nhánh nào** (happy/negative/boundary) của unit.

### Pha D — Detect gap + severity

8. Gán trạng thái mỗi coverage unit:
   - **✅ Covered** — có ≥1 TC map đúng, và (nếu unit có nhánh lỗi/biên) các nhánh chính đã có TC.
   - **⚠️ Weak** — chỉ có happy-path; thiếu **negative/boundary** cho rule/validation/mã lỗi có nhánh; hoặc chỉ map bằng suy luận `?` chưa chắc.
   - **❌ Missing** — không TC nào map.
9. **TC thừa (orphan):** TC không map đơn vị FSD nào → liệt kê riêng. Diễn giải khả năng: (i) test hành vi ngoài phạm vi FSD; (ii) FSD thiếu spec cho hành vi đó (tín hiệu gap FSD → gợi `/gap` hoặc cập nhật FSD). KHÔNG tự kết luận đúng/sai.
10. **Severity** (theo `review-format.md`):
    | Severity | Tiêu chí |
    |----------|----------|
    | CRITICAL | Luồng chính / giao dịch tiền / phân quyền-bảo mật / mã lỗi chặn — **Missing** |
    | HIGH | Business rule, validation bắt buộc, mã lỗi nghiệp vụ — Missing/Weak |
    | MEDIUM | Enumeration, nhánh phụ, validation định dạng — Missing/Weak |
    | LOW | NFR mô tả, edge case hiếm |
11. **Coverage %:** `covered / tổng đơn vị` (Weak tính riêng, KHÔNG gộp vào covered). Tách theo loại đơn vị (FR / FLOW / VAL / ERR / ENUM) để thấy chỗ hở tập trung.

### Pha E — In báo cáo (report-first)

12. In ra chat (terse):
    ```
    📊 Coverage {feature}: {C}/{T} đơn vị ✅ ({pct}%) · ⚠️ {W} yếu · ❌ {Mi} thiếu · 🔶 {O} TC thừa

    Theo loại: FR {x/y} · FLOW {x/y} · VAL {x/y} · ERR {x/y} · ENUM {x/y}

    ❌ Thiếu (ưu tiên severity):
    | ID đơn vị | Mô tả | Severity | Đề xuất TC |
    | ERR-REP-005 | Bắt buộc chọn nhân viên | HIGH | TC negative: bỏ trống NV → báo lỗi |
    | ...

    ⚠️ Yếu: {liệt kê đơn vị + thiếu nhánh gì}
    🔶 TC thừa: {id TC + 1 dòng vì sao không map}
    ❓ OQ: {phần FSD trống/Hint không đo được}
    ```

### Pha F — Write report (L1)

13. **L1 plan preview** (prose, `ba-conventions` Mục 5) → **Write** `docs/test-coverage/{feature}.md` theo `_templates/tc-coverage-report.md` (frontmatter v2 + changelog). File đã tồn tại → L2 diff. `--report-only` → bỏ Pha F.

### Pha G — Recommend

14. Đề xuất **test case bổ sung**: mỗi đơn vị Missing/Weak → 1 dòng gợi tiêu đề TC + loại (negative/boundary). Final report:
    ```
    ✅ Coverage review xong: docs/test-coverage/{feature}.md
       Covered {pct}% | Thiếu {Mi} | Yếu {W} | TC thừa {O}
    Recommended next:
      - Bổ sung {Mi+W} test case theo đề xuất (ưu tiên CRITICAL/HIGH)
      - /tc-review lại sau khi cập nhật test case
      - TC thừa → đối chiếu FSD (cập nhật spec hoặc bỏ TC)
    ```

## Gotchas

- **FSD là chuẩn đối chiếu** — đo TC so với FSD, KHÔNG bắt FSD theo TC. Nhưng TC thừa lặp lại nhiều = tín hiệu FSD thiếu → ghi OQ, đừng lờ.
- **Covered ≠ test tốt** — 1 TC happy cho rule có 3 nhánh lỗi vẫn là **Weak**. Đếm theo nhánh, không theo "có hay không có TC".
- **KHÔNG phồng gap giả** — phần FSD trống/`<Hint>`/struck-through không phải "thiếu test"; đó là thiếu **spec** → OQ, loại khỏi mẫu số coverage.
- **Map `?` phải hiện rõ** — coverage % có/không tính map suy luận phải ghi chú; người review cần biết phần nào chắc, phần nào đoán.
- **`.xlsx` parse được trực tiếp** — giải nén zip + ghép sharedStrings vào sheet XML (Pha A.2); KHÔNG cần user export CSV trừ khi parse lỗi. Nhớ copy ra đường dẫn không dấu cách (bsdtar lỗi mở file khi path có khoảng trắng + ký tự lạ).
- **Báo cáo là ảnh chụp tại thời điểm** — FSD hoặc bộ test case đổi → chạy lại `/tc-review`.
- **Truy nguồn từng đơn vị** — mỗi dòng ma trận ghi được "đơn vị này lấy từ Mục nào của FSD" để QA tự kiểm.

## References

- @../../rules/ba-conventions.md
- @../../rules/approval-gate.md
- @../../rules/naming-conventions.md
- @../../rules/review-format.md
- @../../rules/changelog.md
- @../../../_templates/tc-coverage-report.md
