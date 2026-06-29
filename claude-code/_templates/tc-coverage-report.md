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
changelog:
  - {YYYY-MM-DD} | /tc-review | initial coverage review — {C}/{T} covered, {Mi} missing, {W} weak, {O} orphan
---

# Báo cáo độ phủ Test Case — {Feature}

> Đối chiếu bộ test case với FSD `{tên FSD}`. **FSD là chuẩn**; báo cáo đo độ phủ test case so với FSD tại thời điểm {ngày}. Nguồn test case: `{nguồn}`.

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

## 2. Ma trận coverage (FSD → Test Case)

| ID đơn vị | Mô tả (từ FSD) | Nguồn FSD | Test case map | TT thực thi | Trạng thái | Severity |
|-----------|----------------|-----------|---------------|-------------|------------|----------|
| FR-01 | {…} | Mục {n} | TC-001, TC-002 | Passed | ✅ Covered | — |
| ERR-REP-005 | Bắt buộc chọn nhân viên | Main Flow b6 | — | — | ❌ Missing | HIGH |
| VAL-fromdate | From Date hợp lệ | UI Validation | TC-010 (happy) | Passed | ⚠️ Weak | MEDIUM |
| FR-07 | {…} | Mục {n} | TC-030 | Failed | 🟠 Covered-but-Failing | HIGH |
| ENUM-actiontype:Edit | Hành động Sửa | Mục 5.2 | TC-020? | Not Run | ⚠️ Weak (map `?`) | MEDIUM |
| … | | | | | | |

<!-- Trạng thái: ✅ Covered / ⚠️ Weak / 🟠 Covered-but-Failing / ❌ Missing. `?` = map suy luận chưa xác nhận. Cột TT thực thi lấy từ Status của test case. -->

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
