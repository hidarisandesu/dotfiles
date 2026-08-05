#!/bin/bash
# Claude Code ステータス行（3行表示）
#   1行目: vバージョン | モデル | 📂 ディレクトリ | 🌿 gitブランチ | 💬 ターン数
#   2行目: Context: プログレスバー [使用率%] 使用トークン / 上限トークン（K/M単位）
#   3行目: Rate: レート制限使用率（5時間 / 7日間）
input=$(cat)

# --- 必要なフィールドを 1 回の jq でまとめて取り出す（プロセス起動を減らして高速化） ---
#     1フィールド1行で出力し mapfile で配列化。改行区切りなので空フィールドも潰れない。
#     jq | tr -d '\r': Windows ネイティブ jq は CRLF で出力するため \r を除去して正規化。
mapfile -t F < <(
  printf '%s' "$input" | jq -r '
    (.model.display_name // ""),
    (.model.id // ""),
    (.workspace.current_dir // ""),
    (.transcript_path // ""),
    (.context_window.used_percentage // 0 | floor),
    (.context_window.total_input_tokens // 0),
    (.context_window.context_window_size // 0),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.version // "")
  ' | tr -d '\r'
)
MODEL="${F[0]}"; MODEL_ID="${F[1]}"; DIR_FULL="${F[2]}"; TRANSCRIPT="${F[3]}"
PCT="${F[4]:-0}"; USED="${F[5]:-0}"; MAX="${F[6]:-0}"
FIVE_H="${F[7]}"; WEEK="${F[8]}"; VER="${F[9]}"

# --- モデル名: display_name を優先。バージョン数字が無ければ id から整形（claude-opus-4-8[1m] -> opus 4.8） ---
if [ -z "$MODEL" ] || ! printf '%s' "$MODEL" | grep -q '[0-9]'; then
  MODEL=$(printf '%s' "$MODEL_ID" | sed -E 's/\[[^]]*\]//; s/^claude-//; s/-([0-9]+)-([0-9]+)$/ \1.\2/; s/-([0-9]+)$/ \1/')
fi
[ -z "$MODEL" ] && MODEL="?"

# --- ディレクトリ名（Windows の \ と Unix の / の両対応で末尾セグメントだけ抽出） ---
DIR=$(printf '%s' "$DIR_FULL" | grep -oP '[^/\\]+$')
[ -z "$DIR" ] && DIR="?"

# --- git ブランチ（JSON に無いので git を叩く。cwd に依存せず -C で作業ディレクトリを指定） ---
BRANCH=$(git -C "$DIR_FULL" branch --show-current 2>/dev/null)

# --- ターン数: ログから「user 行 − tool_result 行」で人間の発話回数を近似 ---
TURNS=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  TURNS=$(grep '"type":"user"' "$TRANSCRIPT" 2>/dev/null | grep -vc 'tool_result')
fi

# --- 色定義（$'...' で実際の ESC バイトを埋め込むので printf '%s' でそのまま出せる） ---
CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; GRAY=$'\033[90m'; RESET=$'\033[0m'

# --- プログレスバー（使用率でしきい値色分け: 90%+赤 / 70%+黄 / それ未満緑） ---
BAR_WIDTH=12
FILLED=$((PCT * BAR_WIDTH / 100))
[ "$FILLED" -lt 0 ] && FILLED=0
[ "$FILLED" -gt "$BAR_WIDTH" ] && FILLED=$BAR_WIDTH
EMPTY=$((BAR_WIDTH - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

if [ "$PCT" -ge 90 ]; then BAR_COLOR=$RED
elif [ "$PCT" -ge 70 ]; then BAR_COLOR=$YELLOW
else BAR_COLOR=$GREEN; fi

# --- トークン数を K/M 単位に整形（271000 -> 271.0K, 1000000 -> 1.0M） ---
humanize() {
  awk -v n="$1" 'BEGIN{
    if (n >= 1000000) printf "%.1fM", n/1000000;
    else if (n >= 1000) printf "%.1fK", n/1000;
    else printf "%d", n;
  }'
}
# --- レート制限値を整形（空なら "--"、値があれば "21.5%"） ---
fmt_rate() { if [ -n "$1" ]; then printf '%.1f%%' "$1"; else printf '%s' '--'; fi; }

# --- 1行目を組み立て（先頭に Claude Code バージョン。各要素は " | " 区切り。git リポジトリ外ならブランチ表示を省略） ---
LINE1=""
[ -n "$VER" ] && LINE1="${GRAY}v${VER}${RESET} | "
LINE1="${LINE1}${CYAN}${MODEL}${RESET} | 📂 ${DIR}"
[ -n "$BRANCH" ] && LINE1="${LINE1} | 🌿 ${BRANCH}"
LINE1="${LINE1} | 💬 ${TURNS}"

# --- 2行目を組み立て（Context: ヘッダ + バー + 使用率 + トークン K/M） ---
LINE2="Context: ${BAR_COLOR}${BAR}${RESET} [${PCT}%] $(humanize "$USED") / $(humanize "$MAX")"

# --- 3行目を組み立て（Rate: 5時間 / 7日間のレート制限使用率） ---
LINE3="Rate: 5h $(fmt_rate "$FIVE_H") 7d $(fmt_rate "$WEEK")"

printf '%s\n' "$LINE1"
printf '%s\n' "$LINE2"
printf '%s\n' "$LINE3"
