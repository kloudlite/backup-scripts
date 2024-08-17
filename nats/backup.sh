#! /usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

echo "${ENCRYPTION_PASSWORD?Error: env-var is not set}" >/dev/null
echo "${BACKUP_DIR?Error: env-var is not set}" >/dev/null

echo "${NATS_URL?Error: env-var is not set}" >/dev/null

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
TMP_BACKUP_DIR="/tmp/nats-backup_$TIMESTAMP"

mkdir -p "$TMP_BACKUP_DIR"

nats account backup --server="$NATS_URL" "$TMP_BACKUP_DIR" -f

tar cf "${TMP_BACKUP_DIR}.tar" "${TMP_BACKUP_DIR}"
zstd --rm "${TMP_BACKUP_DIR}.tar" -o "${TMP_BACKUP_DIR}.tar.zst"

openssl rand -hex 16 >salt.txt

encrypt() {
  command openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt -in "$1" -out "$1.enc" -pass pass:"$ENCRYPTION_PASSWORD"
}

decrypt() {
  name=$1
  d_name=${name//.enc/}
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in "$name" -out "$d_name" -pass pass:"$ENCRYPTION_PASSWORD"
}

encrypt "$TMP_BACKUP_DIR.tar.zst"

cp "$TMP_BACKUP_DIR"/*.zst.enc "$BACKUP_DIR"

all_backups=$(ls -t "$BACKUP_DIR")

MAX_NUM_BACKUPS=${MAX_NUM_BACKUPS:-10}

idx=1
for backup in $all_backups; do
  if [ $idx -gt $((MAX_NUM_BACKUPS)) ]; then
    rm -rf "$backup"
  fi
  idx=$((idx + 1))
done

echo "Backup Complete."
