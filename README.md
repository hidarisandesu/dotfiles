# dotfiles

個人の設定ファイルを [chezmoi](https://www.chezmoi.io/) で管理するリポジトリ。

- 管理対象: git 設定、Claude Code 設定、bash 設定、oh-my-posh テーマ、[herdr](https://herdr.dev)（AI エージェント対応のターミナルマルチプレクサ）の設定（Windows のみ）、Windows Terminal プロファイル、ツール台帳
- 対応 OS: Windows / Linux
- 公開リポジトリのため、トークン・鍵などの秘密情報は置かない

## セットアップ

新しいマシンでは、次の1行でリポジトリの取得から設定ファイルの配置まで進む。

**Windows**（PowerShell）:

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- -b $env:USERPROFILE\.local\bin init --apply hidarisandesu"
```

**Linux**:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin init --apply hidarisandesu
```

そのあと新しいシェルを開き（Windows は Windows Terminal を再起動して Git Bash プロファイルを開く）、`setup-tools` でツールを番号選択で導入する。詳細な手順は [.claude/WORKFLOW.md](.claude/WORKFLOW.md) にある。

## 役割分担

- **chezmoi apply** — 設定ファイルの配置。例外として Windows の初回だけ、Git for Windows が無ければ導入する
- **setup-tools** — ツール（git・gh・Node.js・Claude Code・jq・oh-my-posh・herdr・フォント・自作 VS Code 拡張）の選択式導入コマンド。台帳は [`tools.yaml`](home/.chezmoidata/tools.yaml)

## リポジトリ構成

```text
dotfiles/
├── .chezmoiroot                       # ソースディレクトリの指定（home）
├── .claude/
│   ├── CLAUDE.md                      # Claude Code 用のリポジトリ運用ルール
│   └── WORKFLOW.md                    # セットアップと運用の手順
├── .gitignore
├── LICENSE
├── home/                              # ソースディレクトリ（この下が ~ に展開される）
│   ├── .chezmoi.toml.tmpl             # chezmoi 自身の設定
│   ├── .chezmoidata/
│   │   └── tools.yaml                 # ツール台帳（名前・用途・導入済み判定・導入コマンド・依存）
│   ├── .chezmoiignore                 # OS 別に展開しないファイルの指定
│   ├── .chezmoiscripts/
│   │   └── run_once_before_install-git.ps1.tmpl  # Windows 初回のみ Git for Windows を導入
│   ├── AppData/                       # Windows のみ展開（Linux では .chezmoiignore で除外）
│   │   ├── Local/Microsoft/Windows Terminal/Fragments/dotfiles/
│   │   │   └── git-bash.json          #   → Windows Terminal の Git Bash プロファイル
│   │   └── Roaming/herdr/
│   │       └── config.toml            #   → herdr の設定
│   ├── dot_bash_profile               # → ~/.bash_profile（Windows のみ）
│   ├── dot_bashrc.tmpl                # → ~/.bashrc
│   ├── dot_claude/                    # → ~/.claude/
│   │   ├── CLAUDE.md                  #   → ~/.claude/CLAUDE.md（ユーザーレベルの指示）
│   │   ├── executable_statusline.sh   #   → ~/.claude/statusline.sh
│   │   └── modify_settings.json       #   → ~/.claude/settings.json（配布キーだけ上書きするマージ配布）
│   ├── dot_config/oh-my-posh/
│   │   └── dracula.omp.json           # → ~/.config/oh-my-posh/dracula.omp.json
│   ├── dot_gitconfig.tmpl             # → ~/.gitconfig
│   └── dot_local/bin/
│       └── executable_setup-tools.tmpl  # → ~/.local/bin/setup-tools（選択式導入コマンド）
└── README.md
```

`home/` が chezmoi のソースディレクトリ（[`.chezmoiroot`](https://www.chezmoi.io/reference/special-files-and-directories/chezmoiroot/) で指定）で、配下のファイルが[命名規則](https://www.chezmoi.io/reference/source-state-attributes/)に従ってホームディレクトリに展開される。`home/` の外にあるファイルは展開されない。

## 参考にする場合

これは個人の設定なので、そのまま適用する用途は想定していない。fork して `dot_gitconfig.tmpl` や `tools.yaml` 等を自分用に書き換えたうえで、「セットアップ」節の1行コマンドにあるユーザー名（`hidarisandesu`）を自分のものに変えて実行する。
