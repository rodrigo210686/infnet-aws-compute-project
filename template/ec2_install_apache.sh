#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Atualiza pacotes e instala Apache + curl
apt-get update -y
apt-get install -y apache2 curl

# Obtém token IMDSv2 (metadata)
TOKEN="$(curl -sS -m 2 -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)"

# Função helper para chamar metadata com/sem token (fallback)
md() {
  local path="$1"
  if [[ -n "${TOKEN:-}" ]]; then
    curl -sS -m 2 -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/${path}" || true
  else
    curl -sS -m 2 "http://169.254.169.254/latest/meta-data/${path}" || true
  fi
}

# Coleta informações
HOSTNAME="$(hostname)"
IP="$(hostname -I | awk '{print $1}')"
AZ="$(md placement/availability-zone)"
INSTANCE_ID="$(md instance-id)"
INSTANCE_TYPE="$(md instance-type)"

# Define cor com base no sufixo da AZ (último caractere)
SUFFIX="${AZ: -1}"
case "$SUFFIX" in
  a|A) COLOR="#8FBC8F" ;;   # Verde
  b|B) COLOR="#FFD700" ;;   # Amarelo
  *)   COLOR="#D3D3D3" ;;   # Cinza (outras zonas)
esac

# Cria a página HTML
cat <<EOF >/var/www/html/index.html
<!DOCTYPE html>
<html lang="pt-br">
<head>
  <meta charset="UTF-8">
  <title>EC2 Auto Scaling Test</title>
  <style>
    :root { --bg: ${COLOR}; }
    body {
      margin: 0; padding: 48px;
      background: var(--bg);
      font-family: Arial, Helvetica, sans-serif;
      color: #222; text-align: center;
    }
    .card {
      display: inline-block; padding: 24px 32px; border-radius: 12px;
      background: rgba(255,255,255,.85); box-shadow: 0 8px 20px rgba(0,0,0,.1);
      text-align: left;
    }
    h1 { margin-top: 0; }
    dt { font-weight: bold; }
    dd { margin: 0 0 12px 0; }
  </style>
</head>
<body>
  <h1>Server Details</h1>
  <div class="card">
    <dl>
      <dt>Hostname</dt><dd>${HOSTNAME}</dd>
      <dt>IP Privado</dt><dd>${IP}</dd>
      <dt>Availability Zone</dt><dd>${AZ}</dd>
      <dt>Instance ID</dt><dd>${INSTANCE_ID}</dd>
      <dt>Instance Type</dt><dd>${INSTANCE_TYPE}</dd>
    </dl>
  </div>
</body>
</html>
EOF

# Habilita e reinicia Apache
systemctl enable apache2
systemctl restart apache2