---
name: tc-review
description: Use when user wants to review/đối chiếu TEST CASE với FSD — đọc FSD (source of truth) + bộ test case có sẵn rồi xác định test case đã cover hết FSD chưa (gap thiếu/yếu/thừa) + có xét trạng thái thực thi (Passed/Failed/Blocked). Triggered by `/tc-review`, "review test case", "test case cover hết FSD chưa", "kiểm tra độ phủ test case", "đối chiếu test case với FSD". Đọc FSD + test case từ Outline hoặc file local (CSV/MD/XLSX); output ma trận coverage + gap vào docs/test-coverage/ (hoặc Outline). KHÁC /userguide (viết hướng dẫn từ FSD) và /cr (review code diff).
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, mcp__outline__get_document, mcp__outline__search_documents, mcp__outline__create_document, mcp__outline__update_document
user-invocable: true
context: fork
argument-hint: "<fsd> <testcase> | --src outline|local | --out docs/test-coverage/{feature}.md | --out-outline <docId> | --report-only | --no-agent"
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
- **Coverage % phải TÍNH, không ước lượng.** Pha B liệt kê đủ đơn vị (có ID); Pha D đếm máy móc `covered / tổng` (Weak KHÔNG gộp vào covered; đơn vị OQ loại khỏi mẫu số). KHÔNG ghi "~80%" cảm tính — phải xuất bảng đếm được.
- **Xét trạng thái thực thi (nếu nguồn có).** Test case thường có cột Status (Passed/Failed/Blocked/Not Run) + có thể có sheet Defect List. **Covered ≠ Passed:** đơn vị được phủ bởi TC đang Failed/Blocked → đánh dấu **Covered-but-Failing/Blocked** (chưa thực sự verify), tách khỏi "Covered sạch".
- **Dùng cột Priority (nếu có).** Phát hiện lệch ưu tiên: đơn vị FSD CRITICAL/HIGH chỉ được phủ bởi TC priority thấp → cảnh báo; nhiều TC priority cao đổ vào phần ngoài phạm vi → cảnh báo.
- **Verify trước khi báo "thiếu"** (Pha D bắt buộc): với mỗi đơn vị định gán ❌ Missing và mỗi TC định gán 🔶 orphan, grep lại nguồn test/FSD bằng từ khóa (mã lỗi, tên field, "trùng/offline/khóa"…) để tránh false missing / false orphan.
- **Agent gate (khuyến nghị).** Trước khi ghi báo cáo, spawn `@testcase-reviewer` soi lại ma trận (bắt false missing/orphan, gap bịa, severity lệch). `--no-agent` để bỏ qua.
- **(E1) Cổng sàng đầu vào — Pha A.0.** Trước khi trích/chấm, kiểm bộ test case + FSD có **đủ cấu trúc tối thiểu** để review không. Không đủ → **KHÔNG chấm coverage** (tránh "review rác"), trả verdict **"Trả về QA/BA"** kèm lý do + **dẫn chứng định lượng** (cột thiếu, % TC thiếu Expected, FSD còn `<Hint>`…). `--force` để bỏ qua gate.
- **(E3) MECE/Exhaustive + traceability 2 chiều.** Trích đơn vị (Pha B) phải **không chồng lấn & phủ hết** (MECE) — có checklist tự soát "còn loại nào trong FSD chưa quét?". Ma trận **2 chiều**: **FSD→TC** (tìm Missing) *và* **TC→FSD** (tìm orphan có hệ thống).
- **(E2) Chấm điểm rubric — Pha D.7.** Ngoài coverage %, chấm **scorecard đa trục** (0–100) có **benchmark**; mỗi lần trừ điểm phải ghi **lý do + dẫn chứng (ID cụ thể) + vì sao trừ nhiều/ít + cách cải thiện**. KHÔNG cho điểm cảm tính.
- **(E4) Phân tầng theo hành trình + chặn theo phụ thuộc.** Gắn đơn vị vào **chặng hành trình** + đánh dấu **happy-path chính**. Đơn vị **nền/đầu hành trình** bị Missing/Failing → **nâng severity** + cảnh báo "phủ phần sau *giảm ý nghĩa*" (onboarding hỏng thì sau pass cũng ít giá trị). Hỗ trợ **nhiều vòng** (`--round N`): vòng 1 tập trung happy-path chính.
- **Report-first.** Phần phân tích in ra chat trước (ma trận terse + gap). **L1 plan** trước khi Write file báo cáo. `--report-only` = chỉ in chat, không ghi file. `--out-outline <docId>` = ghi báo cáo lên trang Outline thay vì file local.
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
/tc-review --out docs/test-coverage/payment.md   # đổi nơi ghi báo cáo (file local)
/tc-review --out-outline <docId>                 # ghi báo cáo lên 1 trang Outline (thay file local)
/tc-review --no-agent           # bỏ bước spawn @testcase-reviewer
/tc-review --force              # bỏ qua cổng sàng đầu vào (Pha A.0), chấm dù input thiếu cấu trúc
/tc-review --round 1            # review theo vòng (vòng 1 = happy-path chính; ghi rõ vòng trong báo cáo)
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
[Pha A] Resolve + ingest: đọc FSD (Outline/local) + test case (Outline/CSV/MD/XLSX). In inventory.
        │
        ▼
[Pha A.0] CỔNG SÀNG (E1): đủ cấu trúc tối thiểu? KHÔNG → trả về QA/BA + dẫn chứng, DỪNG. (--force để bỏ)
        │
        ▼
[Pha B] Trích COVERAGE UNIT từ FSD (MECE/Exhaustive, E3) → gán ID + chặng hành trình (E4).
        Bỏ phần trống/Hint/struck. Xuất danh sách đơn vị đầy đủ (mẫu số).
        │
        ▼
[Pha C] Chuẩn hóa test case → map 2 chiều FSD↔TC (E3); suy luận → đánh `?`.
        │
        ▼
[Pha D] Detect gap: ✅ Covered / ⚠️ Weak / ❌ Missing + verify-before-missing +
        overlay exec-status (Covered-but-Failing) + severity + blocking escalation theo hành trình (E4) +
        cảnh báo lệch priority. Tính coverage % từ danh sách đơn vị.
        │
        ▼
[Pha D.5] (khuyến nghị) Spawn @testcase-reviewer soi ma trận → chỉnh. (--no-agent để bỏ)
        │
        ▼
[Pha D.7] CHẤM RUBRIC (E2): scorecard đa trục 0–100 + benchmark + trừ điểm có dẫn chứng + cải thiện.
        │
        ▼
[Pha E] IN BÁO CÁO ra chat (report-first): scorecard + coverage % + ma trận 2 chiều + gap +
        Covered-but-Failing + blocking + orphan + cảnh báo priority + OQ.
        │
        ▼
[Pha F] L1 plan → Write docs/test-coverage/{feature}.md (hoặc --out-outline lên Outline; bỏ nếu --report-only).
        │
        ▼
[Pha G] Đề xuất test case bổ sung (per Missing/Weak) + recommend next (vòng tiếp theo nếu multi-round).
```

## Approach (chi tiết từng pha)

### Pha A — Resolve & ingest

1. Resolve `fsd` và `testcase` về nguồn (Outline vs local) theo Inputs. Đọc nội dung đầy đủ.
2. **Test case từ CSV/MD:** parse các cột chuẩn nếu có — `ID`, `Title/Summary`, `Precondition`, `Steps`, `Expected`, `Priority`, **`Status` (Passed/Failed/Blocked/Not Run)**, và cột traceability (`FSD ref`/`Requirement`/`UC`). Cột tên khác → ánh xạ mềm.

   **Test case từ `.xlsx` (parse trực tiếp — dùng script đóng kèm):** chạy `_scripts/xlsx2tsv.sh`:
   - Liệt kê sheet: `bash _scripts/xlsx2tsv.sh "<file.xlsx>"` → in tên các sheet.
   - Xuất 1 sheet ra TSV: `bash _scripts/xlsx2tsv.sh "<file.xlsx>" "<tên sheet>"` (khớp gần đúng, không phân biệt hoa thường). Script tự copy sang path tạm không dấu cách, giải nén bằng bsdtar, ghép `sharedStrings.xml` vào `worksheets/sheetN.xml` (map qua `workbook.xml` + `.rels`), giữ đúng vị trí cột → mỗi hàng 1 dòng, cell phân tách TAB.
   - Hàng tiêu đề (Mã Case / Chức năng / Tóm tắt / Điều kiện / Bước / Kết quả mong đợi / Độ ưu tiên / Trạng thái…) định nghĩa cột → đọc các hàng TC theo đó.
   - **Nếu nguồn có sheet "Defect List":** xuất luôn để đối chiếu TC nào đang có defect (phục vụ Covered-but-Failing ở Pha D).
   - **Chỉ khi script lỗi** (xlsx mã hóa, cấu trúc lạ) → mới yêu cầu user export CSV hoặc dán bảng.
3. In **bảng inventory** (chat): `FSD: {N} mục/section` · `Test case: {M} TC ({có/không} cột traceability) · trạng thái: {p} Passed / {f} Failed / {b} Blocked / {n} Not Run`. Thiếu nguồn → dừng hỏi.

### Pha A.0 — Cổng sàng đầu vào (readiness gate, E1)

3b. **Trước khi trích/chấm**, kiểm bộ test case + FSD có đủ cấu trúc tối thiểu để review không. Tiêu chí "đậu" (mặc định):

    | Kiểm | Ngưỡng đậu | Cách đo |
    |------|-----------|---------|
    | TC có **ID** | ≥95% hàng có mã case | đếm hàng có/không ID |
    | TC có **Expected result** | ≥90% có Expected | đếm ô Expected rỗng |
    | TC có **Steps** | ≥90% có bước | đếm ô Steps rỗng |
    | Có cột nhận dạng (ID/Steps/Expected) | đủ 3 | đọc hàng tiêu đề |
    | FSD có nội dung kiểm thử được | ≥1 đơn vị thật (không toàn `<Hint>`/trống) | quét nhanh |

3c. **Nếu KHÔNG đậu** → KHÔNG chấm coverage. Trả verdict **"⛔ Trả về QA/BA"** kèm:
    - **Lý do** ngắn (cái gì thiếu).
    - **Dẫn chứng định lượng** (vd "32/180 TC thiếu Expected", "không có cột traceability", "FSD §5.3, §5.6 còn `<Hint>`").
    - **Việc cần làm** để đủ điều kiện review.
    - DỪNG (không sang Pha B). `--force` để bỏ qua gate và chấm dù thiếu (ghi rõ cảnh báo trong báo cáo).

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
6. **MECE/Exhaustive self-check (E3)** — sau khi trích, tự soát để **không sót, không chồng**:
   - **Exhaustive:** đã quét **mọi** mục FSD chưa? Đặc biệt: mọi FR, **mọi bước** Main Flow, **mọi mã lỗi** trong Error Matrix, **mọi giá trị** enum (không chỉ vài cái mẫu), mọi field × mỗi rule (bắt buộc/định dạng/khoảng). Tự hỏi: "loại đơn vị nào trong FSD chưa có dòng nào?".
   - **Mutually Exclusive:** không có 2 đơn vị trùng nội dung (gộp nếu trùng).
7. **Gắn chặng hành trình + happy-path (E4)** — mỗi đơn vị gán `journey` (vd `onboarding` / `signin` / `core` / `admin`…) suy từ thứ tự use case/flow trong FSD, và đánh dấu đơn vị thuộc **happy-path chính**. Đơn vị **nền** (đầu hành trình, các đơn vị khác phụ thuộc) → đánh dấu `foundational` để Pha D áp blocking. *(FSD không nêu rõ thứ tự → suy theo thứ tự UC/section; không chắc thì ghi OQ, không bịa.)*
8. **Xuất danh sách đơn vị đầy đủ (đếm được)** — giữ list `{ID | loại | mô tả | nguồn Mục | journey | foundational?}` cho TẤT CẢ đơn vị. Đây là **mẫu số** để tính coverage % ở Pha D (đếm máy móc). Số đơn vị OQ (FSD chưa spec) tách riêng, không vào mẫu số.

### Pha C — Chuẩn hóa test case + map

6. Chuẩn hóa mỗi TC: `id`, `mục tiêu`, `loại` (happy / negative / boundary — suy từ expected nếu không ghi rõ), `bước`, `expected`, **`priority`** (nếu có), **`status` thực thi** (Passed/Failed/Blocked/Not Run nếu có).
7. **Map TC → coverage unit:**
   - (a) **Traceability tường minh:** TC có cột FSD ref/Requirement/UC → map thẳng, đối chiếu xem ref có tồn tại trong đơn vị Pha B (ref sai/lạc → đánh dấu).
   - (b) **Suy luận:** không có cột ref → match theo expected/từ khóa/tên field/mã lỗi. Map suy luận **luôn kèm `?`** để người review xác nhận.
   - 1 TC map được nhiều unit thì ghi nhiều; ghi rõ TC đó test **nhánh nào** (happy/negative/boundary) của unit.
   - **Lập ma trận 2 chiều (E3):** (i) **FSD→TC** — mỗi đơn vị có những TC nào (→ tìm Missing/Weak ở Pha D); (ii) **TC→FSD** — mỗi TC map đơn vị nào (→ TC nào **không map gì** = ứng viên orphan, soát ở Pha D). Hai chiều phải nhất quán.

### Pha D — Detect gap + severity

8. Gán trạng thái mỗi coverage unit:
   - **✅ Covered** — có ≥1 TC map đúng, và (nếu unit có nhánh lỗi/biên) các nhánh chính đã có TC.
   - **⚠️ Weak** — chỉ có happy-path; thiếu **negative/boundary** cho rule/validation/mã lỗi có nhánh; hoặc chỉ map bằng suy luận `?` chưa chắc.
   - **❌ Missing** — không TC nào map.
9. **Verify trước khi chốt Missing/orphan (BẮT BUỘC):** với MỖI đơn vị định gán ❌ Missing → grep lại nguồn test bằng từ khóa (mã lỗi, tên field, "trùng/offline/khóa…") xác nhận thật sự không có TC (tránh false missing). Với MỖI TC định gán 🔶 orphan → grep lại FSD xác nhận FSD thật sự không spec (tránh false orphan, vd "+N more", reconciliation). Chỉ giữ Missing/orphan sau khi verify.
10. **Overlay trạng thái thực thi (nếu nguồn có Status):** đơn vị ✅ Covered nhưng TC phủ đang **Failed/Blocked** → đổi nhãn **⚠️ Covered-but-Failing/Blocked** (có TC nhưng chưa thực sự verify). Đối chiếu sheet Defect List nếu có.
11. **TC thừa (orphan):** TC không map đơn vị FSD nào → liệt kê riêng. Diễn giải khả năng: (i) test hành vi ngoài phạm vi FSD; (ii) FSD thiếu spec cho hành vi đó (tín hiệu gap FSD → gợi `/gap` hoặc cập nhật FSD). KHÔNG tự kết luận đúng/sai.
12. **Severity** (theo `review-format.md`):
    | Severity | Tiêu chí |
    |----------|----------|
    | CRITICAL | Luồng chính / giao dịch tiền / phân quyền-bảo mật / mã lỗi chặn — **Missing** |
    | HIGH | Business rule, validation bắt buộc, mã lỗi nghiệp vụ — Missing/Weak |
    | MEDIUM | Enumeration, nhánh phụ, validation định dạng — Missing/Weak |
    | LOW | NFR mô tả, edge case hiếm |
13. **Cảnh báo lệch ưu tiên (nếu có cột Priority):** đơn vị CRITICAL/HIGH chỉ được phủ bởi TC priority thấp → flag "ưu tiên test chưa tương xứng". Nhiều TC priority cao đổ vào phần orphan → flag.
13b. **Blocking escalation theo hành trình (E4):** nếu đơn vị `foundational`/đầu hành trình bị ❌ Missing hoặc 🟠 Covered-but-Failing → **nâng severity lên CRITICAL** và gắn cờ 🚧 "chặn hành trình": phủ các chặng sau *giảm ý nghĩa* cho tới khi chặng nền pass. Liệt kê các đơn vị downstream bị ảnh hưởng. (Vd: onboarding/đăng nhập hỏng → coverage tác vụ lõi chưa đáng tin.)
14. **Coverage % — TÍNH từ danh sách đơn vị Pha B (không ước lượng):**
    - `pct = số ✅ Covered (sạch) / tổng đơn vị (không kể OQ) × 100`, làm tròn.
    - Weak và Covered-but-Failing **KHÔNG** gộp vào Covered — báo riêng.
    - Tách % theo loại đơn vị (FR / FLOW / VAL / ERR / ENUM) để thấy chỗ hở tập trung.
    - Ghi rõ: số map suy luận `?` có/không tính vào Covered.

### Pha D.5 — Agent gate (khuyến nghị, bỏ bằng `--no-agent`)

15. Spawn **`@testcase-reviewer`** (Task tool) truyền: ma trận coverage dự kiến (đơn vị + trạng thái + TC map), danh sách orphan, nội dung FSD + test case đã trích. Agent soi false missing/orphan, gap bịa, severity lệch, Weak bị tính Covered (per `review-format.md`). Nhận findings → chỉnh ma trận. Loop ≤2 vòng nếu còn BLOCKING. Ghi nhớ "đã sửa gì theo review" để báo user.

### Pha D.7 — Chấm điểm rubric (E2)

16. Chấm **scorecard đa trục (0–100)**, mỗi trục có **benchmark** + trọng số; mỗi lần trừ điểm **bắt buộc** ghi: *mức trừ · lý do · dẫn chứng (ID cụ thể) · vì sao trừ nhiều/ít · cách cải thiện*.

    | Trục | Trọng số | Benchmark (mốc) | Trừ điểm khi… |
    |------|----------|------------------|---------------|
    | Độ phủ (coverage %) | 30 | ≥95 xuất sắc · 80–94 khá · 60–79 trung bình · <60 yếu | mỗi đơn vị Missing; trừ nặng nếu CRITICAL/foundational |
    | Chiều sâu negative/boundary | 20 | mọi rule/lỗi có nhánh đều có TC | đơn vị chỉ happy-path (Weak) |
    | Sức khỏe thực thi | 15 | 0 CRITICAL Failed/Blocked | mỗi Covered-but-Failing ở luồng chính |
    | Traceability | 10 | có cột FSD ref, map rõ | tỷ lệ map suy luận `?` cao |
    | Cấu trúc/rõ ràng | 10 | TC đủ Steps+Expected | TC thiếu expected/bước |
    | Kỷ luật phạm vi | 10 | ít orphan | nhiều TC ngoài FSD |
    | Hành trình (blocking) | 5 | không chặng nền nào hở | có 🚧 chặn hành trình |

    Quy đổi: tổng điểm có trọng số → xếp hạng (**A ≥90 · B 75–89 · C 60–74 · D <60**). KHÔNG cho điểm cảm tính — mỗi điểm trừ phải truy được về dẫn chứng.

### Pha E — In báo cáo (report-first)

12. In ra chat (terse):
    ```
    🏁 Điểm bộ test: {score}/100 — hạng {A/B/C/D}   (vòng {R} nếu multi-round)
       Độ phủ {x}/30 · Negative/boundary {x}/20 · Sức khỏe thực thi {x}/15 · Traceability {x}/10 · Cấu trúc {x}/10 · Phạm vi {x}/10 · Hành trình {x}/5
       (mỗi trục thấp → 1 dòng: trừ vì {dẫn chứng ID} → cải thiện {…})

    📊 Coverage {feature}: {C}/{T} đơn vị ✅ ({pct}%) · ⚠️ {W} yếu · 🟠 {CF} covered-but-failing · ❌ {Mi} thiếu · 🔶 {O} TC thừa
    (TC: {p} Passed / {f} Failed / {b} Blocked / {n} Not Run)

    Theo loại: FR {x/y} · FLOW {x/y} · VAL {x/y} · ERR {x/y} · ENUM {x/y}

    🚧 Chặn hành trình (nếu có): {đơn vị nền Missing/Failing} → phủ {chặng sau} giảm ý nghĩa

    ❌ Thiếu (ưu tiên severity):
    | ID đơn vị | Mô tả | Journey | Severity | Đề xuất TC |
    | ERR-REP-005 | Bắt buộc chọn nhân viên | signin | HIGH | TC negative: bỏ trống NV → báo lỗi |
    | ...

    ⚠️ Yếu: {liệt kê đơn vị + thiếu nhánh gì}
    🟠 Covered-but-Failing/Blocked: {đơn vị + TC đang Failed/Blocked → chưa thực sự verify}
    🔶 TC thừa (TC→FSD không map): {id TC + 1 dòng vì sao không map}
    ⚖️ Lệch ưu tiên: {đơn vị HIGH chỉ phủ bởi TC priority thấp, nếu có}
    ❓ OQ: {phần FSD trống/Hint không đo được}
    ```

    *(Nếu Pha A.0 không đậu: in thẳng verdict "⛔ Trả về QA/BA" + dẫn chứng, KHÔNG in scorecard/coverage.)*

### Pha F — Write report (L1)

16. **L1 plan preview** (prose, `ba-conventions` Mục 5) → ghi báo cáo theo `_templates/tc-coverage-report.md` (frontmatter v2 + changelog):
    - Mặc định: **Write** `docs/test-coverage/{feature}.md` (file local). File đã tồn tại → L2 diff.
    - `--out-outline <docId>`: ghi lên Outline qua `mcp__outline__update_document` (hoặc `create_document` nếu chưa có) — show diff/preview trước, tránh mojibake (truyền text UTF-8 trực tiếp).
    - `--report-only` → bỏ Pha F.

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
- **Coverage % phải TÍNH** từ danh sách đơn vị Pha B — KHÔNG nhẩm "~80%". Weak/Covered-but-Failing báo riêng, không gộp Covered.
- **Covered ≠ Passed** — đơn vị phủ bởi TC Failed/Blocked là Covered-but-Failing (chưa verify). Luôn xét cột Status nếu nguồn có.
- **Verify trước khi báo Missing/orphan** — grep lại nguồn; đây là chỗ dễ sai nhất (lần chạy thật suýt nhầm "+N more" thành orphan).
- **Dùng script `_scripts/xlsx2tsv.sh`** cho `.xlsx` thay vì dựng pipeline tại chỗ — ổn định, giữ đúng cột.
- **Cổng sàng trước, chấm sau (E1)** — input thiếu cấu trúc thì trả về QA/BA kèm dẫn chứng, ĐỪNG chấm coverage rồi mới than "thiếu nhiều" — điểm thấp do input rác là vô nghĩa.
- **MECE = chống sót (E3)** — chỗ dễ sót nhất: **enum chỉ trích vài giá trị mẫu** (phải lấy hết), bước flow giữa chừng, mã lỗi phụ. Luôn chạy chiều **TC→FSD** để bắt orphan, đừng chỉ FSD→TC.
- **Điểm trừ phải có dẫn chứng (E2)** — mỗi điểm trừ kèm ID cụ thể + cách cải thiện; không cho điểm cảm tính. Benchmark cố định để hai lần chạy so sánh được.
- **Onboarding hỏng → sau pass ít nghĩa (E4)** — đơn vị nền Missing/Failing nâng CRITICAL + cờ 🚧; báo rõ downstream bị ảnh hưởng. Multi-round: vòng 1 chốt happy-path nền trước.
- **Báo cáo là ảnh chụp tại thời điểm** — FSD hoặc bộ test case đổi → chạy lại `/tc-review`.
- **Truy nguồn từng đơn vị** — mỗi dòng ma trận ghi được "đơn vị này lấy từ Mục nào của FSD" để QA tự kiểm.

## References

- @../../rules/ba-conventions.md
- @../../rules/approval-gate.md
- @../../rules/naming-conventions.md
- @../../rules/review-format.md
- @../../rules/changelog.md
- @../../agents/testcase-reviewer.md
- @../../../_templates/tc-coverage-report.md
- @../../../_scripts/xlsx2tsv.sh
