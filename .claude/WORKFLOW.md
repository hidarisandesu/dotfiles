# セットアップと運用

自分のマシンをセットアップし、運用するための手順。chezmoi の一般的な操作（add・edit・apply・update、[命名規則](https://www.chezmoi.io/reference/source-state-attributes/)）は[公式ユーザーガイド](https://www.chezmoi.io/user-guide/daily-operations/)を参照。

## 新しいマシンのセットアップ

### 1. 前提ツールを入れる

- **Linux**: git・curl（ほかに sudo 権限。パッケージ導入で使う）
- **Windows**: [Git for Windows](https://git-scm.com/download/win) と [Scoop](https://scoop.sh/)。Scoop はセットアップスクリプトが使うため必須（ユーザー操作での導入が必要なため、自動導入の対象にしていない）

### 2. GitHub に認証する（編集・プッシュするマシンのみ）

取得して使うだけのマシンは不要（公開リポジトリのため取得に認証は要らない）。設定を編集してプッシュするマシンだけ、`gh` を導入して認証する：

```bash
gh auth login    # HTTPS・ブラウザ認証を選ぶと credential helper も自動設定される
```

- ブラウザが開かない環境（SSH 先・コンテナ等）では、表示される URL とワンタイムコードで認証する
- WSL の認証は Windows 側と独立。WSL 内で別途 `gh auth login` が必要

### 3. ワンライナーを実行する

**Windows は Git Bash、Linux は通常のシェルで**実行する（PowerShell ではない）：

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin init --apply hidarisandesu
```

chezmoi の導入 → リポジトリの取得 → dotfiles の展開 → パッケージ導入まで自動で進む。Linux では最初にセットアップ計画の確認が入る（非対話環境や `DOTFILES_YES=1` では省略）。途中で sudo のパスワードを一度求められる。

### 4. 動作確認する

シェルを開き直してから（適用中に PATH が変わっているため）：

```bash
chezmoi status              # 何も表示されなければ、リポジトリとホームが一致している
ls ~/.claude/               # settings.json と statusline.sh が展開されている
git config --get user.name  # ~/.gitconfig が展開されている
brew --version              # Linux のみ
```

### 5. Claude Code のプラグインを読み込む

初回のみ、Claude Code 内で以下を実行してから再起動する：

```text
/plugin marketplace add hidarisandesu/cc-plugins
```

## 原則: リポジトリが正本

リポジトリ → ホームディレクトリの一方向フローを維持する。

- 設定を変更するときは、ホーム側（`~/.claude/` など）ではなく正本（`home/` 配下）を編集する
- ホーム側を直接編集してしまった場合は `chezmoi re-add` で正本に取り込み、乖離を解消する
- 乖離の有無は `chezmoi status` / `chezmoi diff` で確認できる

## 変更の同期

コミット・プッシュ・`chezmoi apply` は sync-dotfiles スキルで一括実行する。Claude Code で「同期して」「push して」等と言えば自動起動する。手順を個別に実行すると漏れが出るため、同期は必ずスキル経由で行う。

このスキルは [cc-plugins](https://github.com/hidarisandesu/cc-plugins) の skills-core として配布している。

別マシンで最新の変更を取り込むときは：

```bash
chezmoi update -v    # git pull --autostash --rebase + chezmoi apply
```

## パッケージの追加

[`packages.yaml`](../home/.chezmoidata/packages.yaml) に 1 行追加して同期する。次回の `chezmoi apply` 時に `.chezmoiscripts/` のスクリプトが brew（Linux）/ scoop（Windows）で導入する。

## Claude Code プラグインの更新

プラグインの実体は [cc-plugins](https://github.com/hidarisandesu/cc-plugins) にあり、`settings.json` の `enabledPlugins` / `extraKnownMarketplaces` で宣言している。cc-plugins 側を更新したら、各マシンで以下を実行して反映する（サードパーティのマーケットプレイスは自動更新されない）：

```text
/plugin marketplace update cc-plugins
```

## クリーンアップ（やり直し）

chezmoi とその管理データを削除してから、セットアップのワンライナーを再実行する。

Linux:

```bash
rm -f ~/.local/bin/chezmoi
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi
```

Windows（Git Bash）:

```bash
rm -f ~/.local/bin/chezmoi.exe
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi
rm -rf "$LOCALAPPDATA/chezmoi"
```

scoop 経由でインストールした場合は先に `scoop uninstall chezmoi` を実行する。
