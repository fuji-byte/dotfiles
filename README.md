# dotfiles

## インストール

```bash
cd ~
mkdir dotfiles
git clone https://github.com/fuji-byte/dotfiles ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh

# sudoが使えない環境でのインストール
環境があるPCからSCPを使ってインストール
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
