# dotfiles

設定ファイルを [chezmoi](https://www.chezmoi.io/) で管理するリポジトリ。

- 管理対象: git 設定、Claude Code 設定、OS 別パッケージ定義
- 対応 OS: Windows / Linux

## リポジトリ構成

```text
dotfiles/
├── .chezmoiroot                       # ソースディレクトリの指定（home）
├── .claude/
│   ├── CLAUDE.md                      # Claude Code 用のリポジトリ運用ルール
│   └── WORKFLOW.md                    # セットアップと運用の手順（所有者向け）
├── home/                              # ソースディレクトリ（この下が ~ に展開される）
│   ├── .chezmoi.toml.tmpl             # chezmoi 自身の設定
│   ├── .chezmoidata/
│   │   └── packages.yaml              # OS 別パッケージリスト
│   ├── .chezmoiignore                 # 展開しないファイルの指定
│   ├── .chezmoiscripts/               # apply 時に自動実行されるスクリプト
│   │   ├── linux/
│   │   └── windows/
│   ├── dot_claude/                    # → ~/.claude/
│   │   ├── executable_statusline.sh   #   → ~/.claude/statusline.sh
│   │   └── settings.json              #   → ~/.claude/settings.json
│   └── dot_gitconfig.tmpl             # → ~/.gitconfig
└── README.md
```

`home/` が chezmoi のソースディレクトリ（[`.chezmoiroot`](https://www.chezmoi.io/reference/special-files-and-directories/chezmoiroot/) で指定）で、配下のファイルが[命名規則](https://www.chezmoi.io/reference/source-state-attributes/)に従ってホームディレクトリに展開される。`home/` の外にあるファイルは展開されない。パッケージの導入は apply 時にスクリプトが行い、対象は [`packages.yaml`](home/.chezmoidata/packages.yaml) で管理している。

## 参考にする場合

これは個人の設定なので、そのまま適用する用途は想定していない。fork して `dot_gitconfig.tmpl` 等を自分用に書き換えたうえで、[chezmoi 公式のクイックスタート](https://www.chezmoi.io/quick-start/)に従って適用する。

セットアップと運用の手順（所有者向け）は [.claude/WORKFLOW.md](.claude/WORKFLOW.md) にある。
