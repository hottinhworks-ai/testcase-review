<!--
TEMPLATE — Báo cáo độ phủ Test Case ↔ FSD (output của /tc-review).
Ghi vào docs/test-coverage/{feature}.md. Frontmatter v2 + changelog.
Nguyên tắc: FSD là source of truth; KHÔNG bịa đơn vị cho phần FSD trống; map suy luận đánh `?`.
-->
---
type: test-coverage-report
feature: "{feature}"
fsd_source: "{Outline urlId / đường dẫn file FSD}"
testcase_source: "{Outline urlId / đường dẫn file test case}"
status: draft
owner: "@{current_user}"
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
coverage_pct: {pct}
score: {score}            # điểm rubric 0–100 (Pha D.7)
grade: {A|B|C|D}
gate_status: {pass|returned}   # cổng sàng đầu vào (Pha A.0)
round: {R}                # vòng review (nếu multi-round)
changelog:
  - {YYYY-MM-DD} | /tc-review | initial coverage review — score {score}, {C}/{T} covered, {Mi} missing, {W} weak, {O} orphan
---

# Báo cáo độ phủ Test Case — {Feature}

> Đối chiếu bộ test case với FSD `{tên FSD}`. **FSD là chuẩn**; báo cáo đo độ phủ test case so với FSD tại thời điểm {ngày}. Nguồn test case: `{nguồn}`. {Vòng {R} nếu multi-round.}

## 0. Cổng sàng đầu vào (readiness)

**Kết quả:** ✅ Đậu — đủ cấu trúc để review.
*(Nếu KHÔNG đậu → ghi: ⛔ **Trả về QA/BA** + lý do + dẫn chứng định lượng (cột thiếu, % TC thiếu Expected, FSD còn `<Hint>`) + việc cần làm; KHÔNG điền các mục dưới.)*

## 1. Tóm tắt

| Chỉ số | Giá trị |
|--------|---------|
| Tổng đơn vị kiểm thử (từ FSD, không kể OQ) | {T} |
| ✅ Covered (sạch) | {C} (**{pct}%** — tính = C/T) |
| ⚠️ Weak (chỉ happy-path / map suy luận) | {W} |
| 🟠 Covered-but-Failing/Blocked (có TC nhưng đang Failed/Blocked) | {CF} |
| ❌ Missing | {Mi} |
| 🔶 Test case thừa (orphan) | {O} |
| Trạng thái thực thi TC | {p} Passed / {f} Failed / {b} Blocked / {n} Not Run |

> Coverage % **được tính** từ danh sách đơn vị (Pha B), không ước lượng. Weak và Covered-but-Failing KHÔNG gộp vào Covered. Đơn vị OQ (FSD chưa spec) đã loại khỏi mẫu số {T}.

**Độ phủ theo loại đơn vị:**

| Loại | Covered / Tổng | Ghi chú |
|------|----------------|---------|
| Functional Requirement (FR) | {x}/{y} | |
| Luồng / bước use case (FLOW) | {x}/{y} | |
| Business rule (BR) | {x}/{y} | |
| Field validation (VAL) | {x}/{y} | |
| Mã lỗi / Exception (ERR/EX) | {x}/{y} | |
| Enumeration (ENUM) | {x}/{y} | |
| NFR | {x}/{y} | |

> Lưu ý: map suy luận (đánh `?`) {có/không} tính vào "Covered". {Số map `?` cần QA xác nhận}.

### Điểm bộ test (rubric scorecard) — {score}/100 · hạng {A|B|C|D}

| Trục | Trọng số | Điểm | Trừ vì (dẫn chứng) → cải thiện |
|------|----------|------|-------------------------------|
| Độ phủ | 30 | {x} | {vd: thiếu ERR-02, ERR-04 (HIGH) → bổ sung TC negative} |
| Negative/boundary | 20 | {x} | {VAL-pwd-len chỉ happy → thêm biên} |
| Sức khỏe thực thi | 15 | {x} | {FR-05 Failed (DEF-12) → fix rồi retest} |
| Traceability | 10 | {x} | {không cột FSD ref → {n} map `?`} |
| Cấu trúc/rõ ràng | 10 | {x} | {…} |
| Kỷ luật phạm vi | 10 | {x} | {…} |
| Hành trình (blocking) | 5 | {x} | {…} |

> Mỗi điểm trừ truy được về dẫn chứng (ID). Benchmark: độ phủ ≥95 xuất sắc · 80–94 khá · 60–79 TB · <60 yếu. Hạng: A ≥90 · B 75–89 · C 60–74 · D <60.

## 2. Ma trận coverage (FSD → Test Case)

| ID đơn vị | Mô tả (từ FSD) | Nguồn FSD | Journey | Test case map | TT thực thi | Trạng thái | Severity |
|-----------|----------------|-----------|---------|---------------|-------------|------------|----------|
| FR-01 | {…} | Mục {n} | signin | TC-001, TC-002 | Passed | ✅ Covered | — |
| ERR-REP-005 | Bắt buộc chọn nhân viên | Main Flow b6 | core | — | — | ❌ Missing | HIGH |
| VAL-fromdate | From Date hợp lệ | UI Validation | core | TC-010 (happy) | Passed | ⚠️ Weak | MEDIUM |
| FR-07 | {…} | Mục {n} | onboarding | TC-030 | Failed | 🟠 Covered-but-Failing 🚧 | CRITICAL |
| ENUM-actiontype:Edit | Hành động Sửa | Mục 5.2 | admin | TC-020? | Not Run | ⚠️ Weak (map `?`) | MEDIUM |
| … | | | | | | | |

<!-- Trạng thái: ✅ Covered / ⚠️ Weak / 🟠 Covered-but-Failing / ❌ Missing. 🚧 = chặn hành trình. `?` = map suy luận chưa xác nhận. Journey = chặng hành trình (E4). -->

### Ma trận ngược (TC → FSD) — soát orphan

| Test case | Map đơn vị FSD | Ghi chú |
|-----------|----------------|---------|
| TC-001 | FR-01 | |
| TC-099 | — | 🔶 orphan (xem Mục 4) |
| … | | |

<!-- Chiều TC→FSD: TC nào map "—" = ứng viên orphan; đối chiếu lại FSD (grep) trước khi kết luận. -->

## 3. Gap chi tiết

### ❌ Thiếu (Missing) — theo severity

**CRITICAL**
- `{ID}` — {mô tả}. Nguồn: {Mục}. → cần TC: {gợi ý}.

**HIGH**
- `{ID}` — {…}

**MEDIUM / LOW**
- `{ID}` — {…}

### ⚠️ Yếu (Weak)

- `{ID}` — đã có {TC happy} nhưng thiếu **{negative / boundary}**: {nhánh cụ thể, vd "To Date < From Date", "vượt 6 chữ số"}.

### 🟠 Covered-but-Failing/Blocked (có TC nhưng chưa thực sự verify)

- `{ID}` — phủ bởi {TC} nhưng đang **{Failed/Blocked}** ({defect ref nếu có}). Coi như chưa verify cho tới khi TC pass.

### 🚧 Chặn hành trình (blocking — E4)

- `{ID}` (chặng **{onboarding/đăng nhập}**, foundational) đang {Missing/Failing} → **phủ các chặng sau giảm ý nghĩa** cho tới khi pass. Downstream bị ảnh hưởng: {danh sách}. → ưu tiên xử lý trước (vòng 1).

### ⚖️ Lệch ưu tiên (nếu nguồn có cột Priority)

- `{ID}` (severity {HIGH/CRITICAL}) chỉ được phủ bởi TC priority **{Low/Medium}** → đề nghị nâng ưu tiên test.

## 4. Test case thừa (orphan) — không map đơn vị FSD nào

| TC | Tóm tắt | Diễn giải |
|----|---------|-----------|
| TC-099 | {…} | Ngoài phạm vi FSD / FSD thiếu spec (→ cân nhắc cập nhật FSD hoặc bỏ TC) |

## 5. Đề xuất test case bổ sung

Ưu tiên CRITICAL → HIGH → MEDIUM:

| # | Đơn vị FSD | Loại TC đề xuất | Tiêu đề gợi ý |
|---|-----------|-----------------|---------------|
| 1 | ERR-REP-005 | Negative | Bỏ trống Nhân viên rồi bấm Show Report → báo lỗi ERR-REP-005 |
| 2 | VAL-fromdate | Boundary | Nhập From Date sai định dạng → chặn + thông báo |
| … | | | |

## 6. Open Questions (chỗ không đo được coverage)

- **OQ-1:** {phần FSD trống/`<Hint>`/bị gạch} — chưa có spec nên không tạo đơn vị kiểm thử; loại khỏi mẫu số coverage. Cần BA bổ sung FSD.
- **OQ-2:** {test case map mơ hồ} — cần QA xác nhận TC-xxx có thực sự cover {ID đơn vị} không.

<!-- Đếm theo nhánh, không theo "có/không có TC". Không bịa đơn vị cho phần FSD chưa spec. -->
