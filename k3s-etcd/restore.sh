#! /usr/bin/env bash

# READ more [here](https://docs.k3s.io/cli/etcd-snapshot?etcdsnap=High+Availability)
set -o errexit
set -o nounset
set -o pipefail

echo "${ENCRYPTION_PASSWORD?Error: env-var is not set}" >/dev/null

name=$1
dest_name=${name//.enc/}
openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in "$name" -out "$dest_name" -pass pass:"$ENCRYPTION_PASSWORD"

d_filename=${dest_name//.zst/}
zstd -d "$dest_name" -o "$d_filename"

# systemctl stop k3s
# k3s server \
#   --cluster-reset \
#   --cluster-reset-restore-path="$d_filename"
