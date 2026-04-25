# dotfiles

## インストール

```bash
cd ~
mkdir dotfiles
git clone https://github.com/fuji-byte/dotfiles ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

# sudoが使えない環境でのインストール
環境があるPCからSCPを使ってインストール
```bash
scp -r ~/.zshrc ~/.p10k.zsh ~/powerlevel10k ~/.zsh ~/.fzf* user@remote:~
# zshのインストール
curl -L -o zsh.tar.xz https://sourceforge.net/projects/zsh/files/latest/download
tar xf zsh.tar.xz
cd zsh-5.9
# configure
./configure --prefix=$HOME/.local
# build
make -j$(nproc)
# install
make install
# pathを通す
export PATH="$HOME/.local/bin:$PATH"
# 起動
zsh
```

# ユーザー権限でのパッケージインストール
## fzf
```bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --bin
# pathを通す
export PATH="$HOME/.fzf/bin:$PATH"
```

## zoxide
```bash
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
# pathを通す
export PATH="$HOME/.local/bin:$PATH"
```
