<!--
VÍ DỤ MẪU (synthetic — dữ liệu hư cấu) cho output của /tc-review.
Tính năng giả định "Login & Account" để minh họa, KHÔNG phải dự án thật.
-->
---
type: test-coverage-report
feature: "Login & Account (demo)"
fsd_source: "FSD_Login_Account_v1.0 (demo)"
testcase_source: "TC_Login_Account.xlsx — sheet Login + Account (demo)"
status: draft
owner: "@example"
created: 2026-06-29
updated: 2026-06-29
coverage_pct: 72
changelog:
  - 2026-06-29 | /tc-review | initial coverage review — 13/18 covered, 3 missing, 2 weak, 2 orphan
---

# Báo cáo độ phủ Test Case — Login & Account (demo)

> Đối chiếu bộ test case với FSD `FSD_Login_Account_v1.0`. **FSD là chuẩn.** Đây là **ví dụ mẫu** minh họa output của `/tc-review` (dữ liệu hư cấu).

## 1. Tóm tắt

| Chỉ số | Giá trị |
|--------|---------|
| Tổng đơn vị kiểm thử (từ FSD, không kể OQ) | 18 |
| ✅ Covered (sạch) | 13 (**72%** — tính = 13/18) |
| ⚠️ Weak (chỉ happy-path / map suy luận) | 2 |
| 🟠 Covered-but-Failing/Blocked | 1 |
| ❌ Missing | 2 |
| 🔶 Test case thừa (orphan) | 2 |
| Trạng thái thực thi TC | 20 Passed / 1 Failed / 1 Blocked / 0 Not Run |

> Coverage % **được tính** từ danh sách đơn vị (Pha B), không ước lượng. Weak & Covered-but-Failing không gộp vào Covered. 1 đơn vị OQ đã loại khỏi mẫu số 18.

**Độ phủ theo loại đơn vị:** FR 5/6 · FLOW 3/3 · VAL 3/4 · ERR 2/4 · ENUM 0/1.

## 2. Ma trận coverage (FSD → Test Case)

| ID đơn vị | Mô tả (từ FSD) | Nguồn FSD | Test case map | TT thực thi | Trạng thái | Severity |
|-----------|----------------|-----------|---------------|-------------|------------|----------|
| FR-01 | Đăng nhập username/password | §5.1 | TC-LOGIN-001, 002 | Passed | ✅ Covered | — |
| ERR-01 | Username để trống → báo lỗi | §5.1 b4 | TC-LOGIN-003 | Passed | ✅ Covered | — |
| ERR-02 | Username chứa ký tự lạ → báo lỗi | §5.1 b3 | — | — | ❌ Missing | HIGH |
| VAL-pwd-len | Mật khẩu 4–16 ký tự | UI Validation | TC-LOGIN-010 (happy) | Passed | ⚠️ Weak | MEDIUM |
| FR-05 | Khóa tài khoản sau N lần sai | §5.1 b13 | TC-LOGIN-020 | Failed | 🟠 Covered-but-Failing | HIGH |
| ERR-04 | Phiên hết hạn khi đăng xuất | §5.2 | — | — | ❌ Missing | MEDIUM |
| ENUM-role:Admin/Staff | Phân vai trò | §5.3 | TC-ACC-030? | Blocked | ⚠️ Weak (map `?`) | MEDIUM |
| … | | | | | | |

## 3. Gap chi tiết

### ❌ Thiếu (Missing)

**HIGH**
- `ERR-02` — Username chứa ký tự lạ: FSD §5.1 b3 định nghĩa nhưng không TC nào test. → cần TC negative.

**MEDIUM**
- `ERR-04` — Phiên hết hạn khi đăng xuất: không TC. → cần TC.

### ⚠️ Yếu (Weak)
- `VAL-pwd-len` — có TC happy (đúng độ dài); thiếu boundary (3 ký tự / 17 ký tự / rỗng).

### 🟠 Covered-but-Failing/Blocked
- `FR-05` — phủ bởi TC-LOGIN-020 nhưng đang **Failed** (DEF-12). Coi như chưa verify cho tới khi pass.

### ⚖️ Lệch ưu tiên
- `FR-05` (HIGH) chỉ có 1 TC priority Medium → nên nâng ưu tiên.

## 4. Test case thừa (orphan)

| TC | Tóm tắt | Diễn giải |
|----|---------|-----------|
| TC-LOGIN-099 | Đăng nhập bằng vân tay | Ngoài phạm vi FSD (FSD chưa spec biometric) → cân nhắc bổ sung FSD hoặc bỏ |
| TC-ACC-088 | Đổi avatar | Ngoài phạm vi FSD |

## 5. Đề xuất test case bổ sung

| # | Đơn vị FSD | Loại TC | Tiêu đề gợi ý |
|---|-----------|---------|---------------|
| 1 | ERR-02 | Negative | Username chứa chữ/ký tự đặc biệt → báo lỗi, chặn đăng nhập |
| 2 | ERR-04 | Negative | Truy cập sau đăng xuất → phiên hết hạn, chuyển về login |
| 3 | VAL-pwd-len | Boundary | Mật khẩu 3 / 17 ký tự → chặn |

## 6. Open Questions

- **OQ-1:** §5.4 (Đăng nhập SSO) còn `<Hint>` — chưa spec → loại khỏi mẫu số coverage; cần BA bổ sung.
- **OQ-2:** TC-ACC-030 map `?` vào ENUM-role — cần QA xác nhận.

<!-- Đếm theo nhánh; không bịa đơn vị cho phần FSD chưa spec; Covered ≠ Passed. -->
