#! /usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

echo "${ENCRYPTION_PASSWORD?Error: env-var is not set}" >/dev/null
echo "${BACKUP_DIR?Error: env-var is not set}" >/dev/null

mkdir -p "$BACKUP_DIR"

SNAPSHOTS_DIR="${SNAPSHOTS_DIR:-/var/lib/rancher/k3s/server/db/snapshots}"

[ -d "$SNAPSHOTS_DIR" ] || (echo "SNAPSHOTS_DIR ($SNAPSHOTS_DIR) does not exist, exiting." && exit 1)

TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
TMP_BACKUP_DIR="/tmp/k3s-etcd-snapshots-backup_$TIMESTAMP"

mkdir -p "$TMP_BACKUP_DIR"

cp "$SNAPSHOTS_DIR"/* "$TMP_BACKUP_DIR"

openssl rand -hex 16 >salt.txt

encrypt() {
  command openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt -in "$1" -out "$1.enc" -pass pass:"$ENCRYPTION_PASSWORD"
}

decrypt() {
  name=$1
  d_name=${name//.enc/}
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in "$name" -out "$d_name" -pass pass:"$ENCRYPTION_PASSWORD"
}

for snapshot in "$TMP_BACKUP_DIR"/*; do
  zstd --rm "$snapshot" -o "$snapshot.zst"
  encrypt "$snapshot.zst"
done

cp "$TMP_BACKUP_DIR"/*.zst.enc "$BACKUP_DIR"

all_backups=$(ls -t "$BACKUP_DIR")

MAX_NUM_BACKUPS=${MAX_NUM_BACKUPS:-10}

idx=1
for backup in $all_backups; do
  if [ $idx -gt $((MAX_NUM_BACKUPS)) ]; then
    echo rm -rf "$backup"
  fi
  idx=$((idx + 1))
done
