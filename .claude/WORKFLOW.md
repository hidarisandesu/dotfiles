# セットアップと運用

自分のマシンをセットアップし、運用するための手順を記す。chezmoi の一般的な操作（add・edit・apply・update、[命名規則](https://www.chezmoi.io/reference/source-state-attributes/)）は[公式ユーザーガイド](https://www.chezmoi.io/user-guide/daily-operations/)を参照する。

役割は2つに分かれる:

- **chezmoi apply** — 設定ファイルの配置。例外として Windows の初回だけ、Git for Windows が無ければ導入する（run_once スクリプト）
- **setup-tools** — 道具の選択導入。台帳は [`tools.yaml`](../home/.chezmoidata/tools.yaml)

## 新しいマシンのセットアップ

### 1. chezmoi を導入して適用する（1行）

**Windows**（PowerShell に貼る。標準搭載のシェルなので前準備なし）:

```powershell
iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- -b $env:USERPROFILE\.local\bin init --apply hidarisandesu"
```

**Linux**（curl が無ければ先に `sudo apt-get update && sudo apt-get install -y curl`）:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin init --apply hidarisandesu
```

この1行で「chezmoi の導入（`~/.local/bin`）→ リポジトリの取得（公開なので認証不要）→ Windows のみ: Git for Windows の導入（UAC の確認が出たら許可）→ 設定ファイルの配置」まで進む。手順3で使う setup-tools コマンドも、この配置で `~/.local/bin/setup-tools` に置かれる。Windows で Git for Windows の導入に失敗した場合（winget が使えない等）は、[Git for Windows](https://git-scm.com/download/win) を手動で導入してから同じ1行を再実行する。

### 2. シェルを開く

- **Windows**: Windows Terminal を起動（既に開いていたら全ウィンドウ終了 → 再起動）すると "Git Bash" プロファイルが現れるので、それを開く。以降の手順は Git Bash で行う
- **Linux**: シェルを開き直す（`.bashrc` が `~/.local/bin` を PATH に載せる）

### 3. setup-tools で道具を導入する

```bash
setup-tools
```

一覧（`*` = 導入済み、番号 = 未導入。依存と用途をツリー表示）から番号で選ぶと、未導入の依存も自動で同時に入る。使う項目が `*` になるまで繰り返す。

- 「シェルを開き直して再実行」と案内されたら従う（winget で入れた道具は新しいシェルでないと見えない）
- VS Code は手動導入（URL が表示される）
- サーバー用途の機では GUI 系（herdr（AI エージェント対応のターミナルマルチプレクサ）・フォント・VS Code 系）を選ばなくてよい

### 4. gh を認証する（gh を使う道具を入れるとき）

フォントと自作 VS Code 拡張の導入は GitHub のリリース取得を伴うため、gh の認証が必要（setup-tools が未認証を検知して案内する）:

```bash
gh auth login   # ブラウザが開かない環境では、表示される URL とワンタイムコードで認証
```

- `gh auth setup-git` は実行しない（chezmoi 管理下の `~/.gitconfig` に書き込んで乖離を作る）。push の認証は、Windows では Git for Windows 同梱の Git Credential Manager が、Linux では管理版 `.gitconfig` の credential helper 設定（gh に委譲）が担う
- WSL の認証は Windows 側と独立（WSL 内で別途実行する）

### 5. 仕上げ（GUI のある機のみ・順不同）

| 作業 | 内容 |
|---|---|
| herdr の Claude Code 統合 | `herdr integration install claude`（hook は herdr が自動管理するため chezmoi 管理外） |
| Windows Terminal の既定化 | 設定 → スタートアップ → 既定のプロファイル → Git Bash（プロファイルは Windows Terminal の配布の仕組み（fragment）で配っており、既定プロファイルの指定だけは配布できない） |
| VS Code サインイン | GitHub アカウントでサインインして Settings Sync を有効化する。テーマ・ターミナルフォント（UDEV Gothic NF）・拡張一覧が同期される |
| Claude Code のプラグイン | `/plugin marketplace add hidarisandesu/cc-plugins` → 再起動 → 使うものを `/plugin install <名前>@cc-plugins` で導入 |

## 動作確認

```bash
chezmoi status              # 何も表示されなければ、リポジトリとホームが一致している
setup-tools </dev/null      # 一覧表示のみ。使う項目がすべて * なら導入完了
ls ~/.claude/               # settings.json・statusline.sh・CLAUDE.md が展開されている
git config --get user.name  # ~/.gitconfig が展開されている（Linux では git 導入後に確認）
```

## 原則: リポジトリが正本

リポジトリ → ホームディレクトリの一方向フローを維持する。

- 設定を変更するときは、ホーム側（`~/.claude/` など）ではなく正本（`home/` 配下）を編集する
- ホーム側を直接編集してしまった場合は `chezmoi re-add` で正本に取り込み、乖離を解消する。ただし settings.json は対象外（配布キーだけを正本の値で上書きし、それ以外のキーは実機の値を保つ「マージ配布」のため、取り込むとマシン固有のキーまで正本に入ってしまう。配布キーの変更は正本の modify_settings.json を編集する）
- 乖離の確認は `chezmoi status` / `chezmoi diff` で行う。マシン固有の設定はマージ配布で保持されて乖離にならないため、差分が表示されたらそれは解消すべき乖離である

## 変更の同期

コミット・プッシュ・`chezmoi apply` は sync-dotfiles スキルで一括実行する。Claude Code で「同期して」「push して」等と言えば自動起動する。手順を個別に実行すると漏れが出るため、同期は必ずスキル経由で行う。push の認証は手順4の注記のとおり（Windows は Git Credential Manager、Linux は gh の認証済みが前提）。

このスキルは [cc-plugins](https://github.com/hidarisandesu/cc-plugins) から sync-dotfiles プラグインとして配布されている。

別マシンで最新の変更を取り込むときは:

```bash
chezmoi update -v    # git pull --autostash --rebase + chezmoi apply
```

### 既存マシンの作り直し（手元のクローンが現在の履歴とつながらない機）

履歴を刷新（2026-09）したため、それより前に clone した機は `chezmoi update` でつながらない。つながるかは次の1行で判定できる（`UPDATE_OK` が出れば `chezmoi update -v` だけでよい）:

```bash
chezmoi git -- fetch origin && chezmoi git -- merge-base --is-ancestor HEAD origin/main && echo UPDATE_OK
```

出ない場合は作り直す。退避するのは手元で編集している可能性のある3ファイルだけでよい（それ以外の管理ファイルは正本と同一のはずで、作り直しで同じ内容が配置される）:

```bash
mkdir -p ~/chezmoi-backup
cp -a ~/.bashrc ~/.gitconfig ~/.claude/settings.json ~/chezmoi-backup/
mv ~/.local/share/chezmoi ~/chezmoi-backup/old-source
mv ~/.config/chezmoi ~/chezmoi-backup/old-config
chezmoi init --apply hidarisandesu
```

作り直すと旧構成の導入スクリプト（scoop/brew）が消え、`.bashrc` と herdr の config.toml（Windows のみ）が管理版に置き換わる（機能は同等）。settings.json はマージ配布のため、マシン固有のキー（model・hooks・有効化したプラグイン）は保持される。scoop・brew 本体と導入済みパッケージはアンインストールされない。

退避先に必要なものが無いと確認できたら `~/chezmoi-backup` を削除する。

## ツールの追加

[`tools.yaml`](../home/.chezmoidata/tools.yaml) に項目を追加して同期する（スキーマはファイル冒頭のコメントを参照）。導入コマンドは各ツールの公式手順を確認して書く。台帳の内容は apply 時に setup-tools のスクリプトへ埋め込まれるため、他のマシンでは `chezmoi update` で取り込んでから `setup-tools` を実行する。

## Claude Code プラグインの更新

プラグインの実体は [cc-plugins](https://github.com/hidarisandesu/cc-plugins) にある。このリポジトリが配布するのはマーケットプレイスの場所（settings.json の extraKnownMarketplaces）だけで、ユーザーレベル設定による自動登録は Claude Code の公式ドキュメントで保証されていないため、初回は手順5のとおり `/plugin marketplace add hidarisandesu/cc-plugins` を実行する。どのプラグインを使うかは各マシンで決める:

```text
/plugin install <plugin>@cc-plugins
```

cc-plugins 側を更新したら、各マシンで以下を実行して反映する（サードパーティのマーケットプレイスは自動更新されない）:

```text
/plugin marketplace update cc-plugins
```

## クリーンアップ（やり直し）

chezmoi とその管理データを削除してから、セットアップの手順を再実行する。

Linux:

```bash
rm -f ~/.local/bin/chezmoi
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi
rm -rf ~/.cache/chezmoi
```

Windows（Git Bash）:

```bash
rm -f ~/.local/bin/chezmoi.exe
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi
rm -rf ~/.cache/chezmoi
```
