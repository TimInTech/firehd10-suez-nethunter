#!/system/bin/sh
# setup_termux_aliases.sh - Run directly on device to configure Termux shortcuts

TERMUX_HOME="/data/data/com.termux/files/home"

if [ ! -d "$TERMUX_HOME" ]; then
    echo "[-] Error: Termux home directory ($TERMUX_HOME) does not exist."
    echo "    Please open the Termux app once before running this script."
    exit 1
fi

BASHRC="$TERMUX_HOME/.bashrc"

cat << 'EOF' > "$BASHRC"
echo '=== Kali NetHunter (Fire HD 10) ==='
echo '  Type "nh" or "kali" to enter Kali Linux chroot'
echo '  Type "kex start" to launch KeX Remote Desktop'

alias nh='su -c /system/bin/bootkali'
alias kali='su -c /system/bin/bootkali'
alias kex='su -c /system/bin/kex'
EOF

OWNER=$(stat -c %u:%g "$TERMUX_HOME")
chown "$OWNER" "$BASHRC"
chmod 644 "$BASHRC"

echo "[+] Termux aliases installed successfully in $BASHRC."
