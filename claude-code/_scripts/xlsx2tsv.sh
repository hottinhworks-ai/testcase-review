#!/usr/bin/env bash
# xlsx2tsv.sh — trích nội dung 1 sheet của file .xlsx ra TSV (mỗi hàng 1 dòng, cell phân tách bằng TAB).
# Dùng cho /tc-review khi test case ở dạng Excel. Không cần python/jq — chỉ bsdtar + gawk + sed (sẵn trên Git Bash/Windows).
#
# Cách dùng:
#   bash xlsx2tsv.sh <file.xlsx> [tên-sheet]
#   - Không truyền tên sheet → in danh sách sheet rồi thoát.
#   - Có tên sheet (khớp gần đúng, không phân biệt hoa thường) → in TSV của sheet đó.
#
# Ví dụ:
#   bash xlsx2tsv.sh "Test case/TC_Round2.xlsx"                 # liệt kê sheet
#   bash xlsx2tsv.sh "Test case/TC_Round2.xlsx" Authentication  # xuất TSV sheet Authentication
#
# Lưu ý: tự copy file sang /tmp (path không dấu cách) vì bsdtar lỗi mở file khi path có khoảng trắng + ký tự lạ.

set -euo pipefail

SRC="${1:?Cần đường dẫn file .xlsx}"
SHEET_NAME="${2:-}"
TAR="${TAR:-/c/Windows/System32/tar.exe}"   # bsdtar (libarchive) đọc được zip; override qua biến TAR nếu cần
command -v "$TAR" >/dev/null 2>&1 || TAR="tar"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp "$SRC" "$WORK/book.xlsx"
( cd "$WORK" && "$TAR" -xf book.xlsx ) >/dev/null 2>&1

WB="$WORK/xl/workbook.xml"
RELS="$WORK/xl/_rels/workbook.xml.rels"

# Danh sách sheet: name + rId
list_sheets() {
  tr '>' '\n' < "$WB" | grep -i '<sheet ' \
    | sed -E 's/.*name="([^"]*)".*r:id="([^"]*)".*/\2\t\1/'
}

if [ -z "$SHEET_NAME" ]; then
  echo "# Sheets trong $(basename "$SRC"):"
  list_sheets | cut -f2
  exit 0
fi

# Tìm rId của sheet theo tên (khớp gần đúng, bỏ qua hoa thường + khoảng trắng đầu/cuối)
RID="$(list_sheets | gawk -v want="$(echo "$SHEET_NAME" | tr 'A-Z' 'a-z')" -F'\t' '
  { n=tolower($2); gsub(/^[ \t]+|[ \t]+$/,"",n); if (index(n, want)>0) { print $1; exit } }')"
[ -n "$RID" ] || { echo "Không tìm thấy sheet khớp \"$SHEET_NAME\"." >&2; echo "Có các sheet:" >&2; list_sheets | cut -f2 >&2; exit 1; }

# rId → file sheetN.xml
TARGET="$(tr '>' '\n' < "$RELS" | grep -i "Id=\"$RID\"" | sed -E 's#.*Target="([^"]*)".*#\1#')"
SHEET_XML="$WORK/xl/$TARGET"
[ -f "$SHEET_XML" ] || { echo "Không thấy file sheet: $TARGET" >&2; exit 1; }

# Bảng tra shared string: dòng (idx+1) = chuỗi index idx
SS="$WORK/ss.txt"
tr -d '\n' < "$WORK/xl/sharedStrings.xml" \
 | sed 's/<si>/\n/g' | tail -n +2 \
 | sed -E 's#</si>.*##; s/<[^>]*>//g; s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g; s/&apos;/'"'"'/g; s/&#10;/ \/ /g' \
 > "$SS"

# Tái tạo từng hàng: mỗi <c ... t="s"><v>idx</v></c> → shared string; cell khác lấy <v>.
tr -d '\n' < "$SHEET_XML" | sed 's/<row /\n<row /g' | tail -n +2 \
 | gawk -v ssfile="$SS" '
   BEGIN { i=0; while ((getline line < ssfile) > 0) ss[i++]=line }
   {
     delete cv; maxc=0; line=$0;
     while (match(line, /<c [^>]*r="([A-Z]+)[0-9]+"[^>]*>(<v>[^<]*<\/v>)?<\/c>/, m)) {
       cell=substr(line, RSTART, RLENGTH); match(cell, /r="([A-Z]+)/, c); col=c[1];
       # col letters → số thứ tự cột
       n=0; for (k=1;k<=length(col);k++) n=n*26 + (index("ABCDEFGHIJKLMNOPQRSTUVWXYZ", substr(col,k,1)));
       isS=(cell ~ /t="s"/); val=""; if (match(cell, /<v>([^<]*)<\/v>/, v)) val=v[1];
       txt=isS?ss[val+0]:val;
       if (txt!="" && cv[n]=="") cv[n]=txt;
       if (n>maxc) maxc=n;
       line=substr(line, RSTART+RLENGTH);
     }
     out=""; for (k=1;k<=maxc;k++) { out=out (k>1?"\t":"") cv[k] }
     if (out ~ /[^ \t]/) print out;
   }'
