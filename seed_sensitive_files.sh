#!/bin/bash

# Victim's home directory
HOME_DIR="/home/$(whoami)"

echo "[+] Generating simulated sensitive data in $HOME_DIR..."

# === 1. Browser cookies and passwords (Firefox and Chromium)
mkdir -p "$HOME_DIR/.mozilla/firefox/profile"
echo "SQLite format 3" > "$HOME_DIR/.mozilla/firefox/profile/cookies.sqlite"
echo '{"encrypted": "p4ssw0rd"}' > "$HOME_DIR/.mozilla/firefox/profile/logins.json"
echo "SQLite format 3" > "$HOME_DIR/.mozilla/firefox/profile/places.sqlite"

mkdir -p "$HOME_DIR/.config/chromium/Default"
echo "SQLite format 3" > "$HOME_DIR/.config/chromium/Default/History"
echo "SQLite format 3" > "$HOME_DIR/.config/chromium/Default/Login Data"
echo "SQLite format 3" > "$HOME_DIR/.config/chromium/Default/Web Data"

# === 2. SSH keys
mkdir -p "$HOME_DIR/.ssh"
echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$HOME_DIR/.ssh/id_rsa"
echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$HOME_DIR/.ssh/id_ed25519"
echo "-----BEGIN DSA PRIVATE KEY-----" > "$HOME_DIR/.ssh/id_dsa"
echo "Host github.com\n  IdentityFile ~/.ssh/id_ed25519" > "$HOME_DIR/.ssh/config"

chmod 600 "$HOME_DIR/.ssh/id_rsa" "$HOME_DIR/.ssh/id_ed25519" "$HOME_DIR/.ssh/id_dsa"
chmod 644 "$HOME_DIR/.ssh/config"

# === 3. Terminal history
echo "ls -la" > "$HOME_DIR/.bash_history"
echo "cd Documents" >> "$HOME_DIR/.bash_history"
echo "cat notes.txt" >> "$HOME_DIR/.bash_history"
echo "git status" >> "$HOME_DIR/.bash_history"
echo "python3 script.py" >> "$HOME_DIR/.bash_history"
echo "sudo apt update" >> "$HOME_DIR/.bash_history"
echo "ssh user@server.com" >> "$HOME_DIR/.bash_history"
echo "nano ~/.ssh/config" >> "$HOME_DIR/.bash_history"
echo "curl https://api.example.com" >> "$HOME_DIR/.bash_history"
echo "docker ps -a" >> "$HOME_DIR/.bash_history"

# === 4. .txt files with keywords (backup, secrets, etc.)
echo "password123" > "$HOME_DIR/passwords.txt"
echo "API_KEY=1234567890abcdef" > "$HOME_DIR/secrets_backup.txt"
echo -e "email: user@example.com\nsenha: 123456" > "$HOME_DIR/credentials.txt"
echo "AWS_SECRET_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE" > "$HOME_DIR/aws_keys.txt"
echo "DROPBOX_TOKEN=sl.ABCDEFGHIJKLMNOP" > "$HOME_DIR/dropbox_token.txt"
echo "backup_2024_06_01.tar.gz" > "$HOME_DIR/backups_list.txt"
echo "credit_card=4111-1111-1111-1111" > "$HOME_DIR/cc_info.txt"
echo "GITHUB_TOKEN=ghp_abcdefghijklmn1234567890" > "$HOME_DIR/github_token.txt"
echo "PRIVATE_KEY=MIIBVwIBADANBgkqhkiG9w0BAQEFAASCAT8wggE7AgEAAkEA" > "$HOME_DIR/private_key.pem"
echo "user: admin\npass: admin2024" > "$HOME_DIR/admin_credentials.txt"

# === 5. Email clients
mkdir -p "$HOME_DIR/.thunderbird/profile"
echo "user@example.com:supersecret" > "$HOME_DIR/.thunderbird/profile/logins.json"
echo "imap.example.com" > "$HOME_DIR/.thunderbird/profile/imap_config.txt"

# === 6. VPN configs
mkdir -p "$HOME_DIR/vpn"
echo "client\nremote vpn.example.com 1194" > "$HOME_DIR/vpn/client.ovpn"
echo "vpnuser\nvpnpassword" > "$HOME_DIR/vpn/credentials.txt"

# === 7. GPG keys
mkdir -p "$HOME_DIR/.gnupg"
echo "-----BEGIN PGP PRIVATE KEY BLOCK-----" > "$HOME_DIR/.gnupg/secring.gpg"
chmod 700 "$HOME_DIR/.gnupg"
chmod 600 "$HOME_DIR/.gnupg/secring.gpg"

# === 8. Cloud config files
mkdir -p "$HOME_DIR/.aws"
echo "[default]\naws_access_key_id=AKIAIOSFODNN7EXAMPLE\naws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" > "$HOME_DIR/.aws/credentials"

mkdir -p "$HOME_DIR/.config/gcloud/configurations"
echo "[core]\naccount = user@example.com" > "$HOME_DIR/.config/gcloud/configurations/config_default"

# === 9. Database credentials
echo "DB_USER=admin\nDB_PASS=secretpass" > "$HOME_DIR/db.env"
echo "mysql://admin:secretpass@localhost:3306/mydb" > "$HOME_DIR/db_url.txt"

# === 10. Correct permissions
chown -R $(whoami):$(whoami) "$HOME_DIR/.mozilla" "$HOME_DIR/.config" "$HOME_DIR/.ssh" "$HOME_DIR/.thunderbird" "$HOME_DIR/vpn" "$HOME_DIR/.gnupg" "$HOME_DIR/.aws"

echo "[+] Simulated data created successfully!"