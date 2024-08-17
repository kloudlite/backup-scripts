#! /usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

echo "${ENCRYPTION_PASSWORD?Error: env-var is not set}" >/dev/null
echo "${TARGET_FILE?Error: env-var is not set}" >/dev/null

# other required vars in above format

decompress() {
  zstd --rm "$1" -o "$2"
}

decrypt() {
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in "$1" -out "$2" -pass pass:"$ENCRYPTION_PASSWORD"
}

# TODO: decrypt target file
decrypted_file_name=${TARGET_FILE//.enc/}
decrypt "$TARGET_FILE" "$decrypted_file_name"

# TODO: extract tar if multiple files
# tar -xvf "$decrypted_file_name"
# extracted_file_name=${decrypted_file_name//.tar/}

# TODO: perform restore operations on that extracted file/directory

echo "Restore Complete."
