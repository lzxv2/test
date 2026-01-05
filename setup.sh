#!/bin/bash

echo "=== Setup Arch Linux (proot-distro) ==="
sleep 1

###############################
clear
echo "[0/12] Verificando dependências essenciais..."
# Atualiza repositórios
apt update && apt upgrade -y

# Instala pacotes básicos
for pkg in proot-distro git curl ncurses-utils; do
    if ! command -v $pkg &> /dev/null; then
        echo "Instalando $pkg..."
        pkg install -y $pkg
    else
        echo "$pkg já instalado."
    fi
done
sleep 1

###############################
clear
echo "[1/12] Instalando getnf..."
curl -fsSL https://raw.githubusercontent.com/arnavgr/termux-nf/main/install.sh | bash
sleep 1

###############################
# Perguntar nome do usuário
read -p "Nome do usuário a criar: " USERNAME

# Perguntar se quer senha
read -p "Deseja definir senha? (s/n): " ASKPASS

###############################
clear
echo "[2/12] Executando getnf para escolher fonte..."
echo "Escolha a fonte desejada quando o getnf abrir..."
getnf
sleep 1

###############################
clear
echo "[3/12] Aplicando tema Cherry Midnight no Termux..."
mkdir -p ~/.termux
cat > ~/.termux/colors.properties <<EOL
# Cherry Midnight colors
background = #1c1c1c
foreground = #f8f8f2
color0 = #1c1c1c
color1 = #ff5555
color2 = #50fa7b
color3 = #f1fa8c
color4 = #bd93f9
color5 = #ff79c6
color6 = #8be9fd
color7 = #bbbbbb
color8 = #44475a
color9 = #ff5555
color10 = #50fa7b
color11 = #f1fa8c
color12 = #bd93f9
color13 = #ff79c6
color14 = #8be9fd
color15 = #ffffff
EOL
termux-reload-settings
sleep 1

###############################
clear
echo "[4/12] Instalando Arch Linux..."
proot-distro install archlinux
echo "Arch Linux: [OK]"
sleep 1

###############################
clear
echo "[5/12] Atualizando Arch e instalando pacotes básicos..."
proot-distro exec archlinux -- pacman -Syu --noconfirm
proot-distro exec archlinux -- pacman -S sudo nano curl git fish --noconfirm
sleep 1

###############################
clear
echo "[6/12] Instalando bun runtime..."
proot-distro exec archlinux -- bash -c "curl -fsSL https://bun.sh/install | bash"
proot-distro exec archlinux -- bash -c "echo 'export PATH=\$HOME/.bun/bin:\$PATH' >> /etc/fish/config.fish"
sleep 1

###############################
clear
echo "[7/12] Criando usuário $USERNAME..."
proot-distro exec archlinux -- useradd -m -s /usr/bin/fish "$USERNAME"
proot-distro exec archlinux -- usermod -aG sudo "$USERNAME"

# Definir usuário como padrão da distro
PROOT_CONF="$HOME/.proot-distro/archlinux.sh"
if [ -f "$PROOT_CONF" ]; then
    sed -i "s/^--user .*/--user $USERNAME/" "$PROOT_CONF"
fi

# Definir senha se solicitado
if [[ "$ASKPASS" == "s" || "$ASKPASS" == "S" ]]; then
  read -s -p "Senha: " PASS1
  echo
  read -s -p "Confirmar senha: " PASS2
  echo
  if [[ "$PASS1" == "$PASS2" ]]; then
    proot-distro exec archlinux -- bash -c "echo '$USERNAME:$PASS1' | chpasswd"
    echo "Senha definida com sucesso."
  else
    echo "❌ Senhas não conferem. Usuário criado sem senha."
    proot-distro exec archlinux -- passwd -d "$USERNAME"
  fi
else
  proot-distro exec archlinux -- passwd -d "$USERNAME"
  echo "Usuário criado sem senha."
fi
sleep 1

###############################
clear
echo "[8/12] Baixando repositório test e copiando para fastfetch config..."
proot-distro exec archlinux -- mkdir -p /home/"$USERNAME"/.config/fastfetch
git clone https://github.com/lzxv2/test /tmp/testrepo
proot-distro exec archlinux -- cp -r /tmp/testrepo/* /home/"$USERNAME"/.config/fastfetch/
proot-distro exec archlinux -- chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.config/fastfetch/
rm -rf /tmp/testrepo
sleep 1

###############################
clear
echo "[9/12] Definindo fish como shell padrão e login automático..."
proot-distro exec archlinux -- chsh -s /usr/bin/fish "$USERNAME"
grep -qxF "proot-distro login archlinux --user $USERNAME" ~/.bashrc || \
    echo "proot-distro login archlinux --user $USERNAME" >> ~/.bashrc
sleep 1

###############################
clear
echo "[10/12] Limpeza e finalizações..."
# Nenhum comando adicional por enquanto
sleep 1

###############################
clear
echo "[11/12] Finalizando..."
sleep 1

###############################
clear
echo "[12/12] Setup finalizado com sucesso!"
echo "Usuário $USERNAME criado, fish definido como shell padrão, bun instalado."
echo "Fastfetch configurado com repositório test e tema Cherry Midnight aplicado no Termux."
echo "Ao abrir o Termux, você entrará automaticamente no Arch Linux como $USERNAME."
