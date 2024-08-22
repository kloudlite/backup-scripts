#! /usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

cat <<EOF
                             ↙↙                                       
                            ↘↘↘↘                                      
                          ↘↘↘↘↘↘↘↘                                    
                        ↘↘↘↘↘↘↘↘↘↘↘                                   
                      ↘↘↘↘↘↘↘↘↘↘↘↘                                    
                    ↘↘↘↘↘↘↘↘↘↘↘↘                                      
                  ↖↘↘↘↘↘↘↘↘↘↘↘                                        
                 ↘↘↘↘↘↘↘↘↘↘↘            ↘↘↘                           
               ↘↘↘↘↘↘↘↘↘↘↘            ↘↘↘↘↘↘↘                         
             ↘↘↘↘↘↘↘↘↘↘↘↓           ↘↘↘↘↘↘↘↘↘↘↘                       
           ↘↘↘↘↘↘↘↘↘↘↘↘           ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↙                     
         ↓↘↘↘↘↘↘↘↘↘↘↘           ↓↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘                    
        ↘↘↘↘↘↘↘↘↘↘↘            ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘                  
      ↘↘↘↘↘↘↘↘↘↘↘            ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘                
    ↘↘↘↘↘↘↘↘↘↘↘←           ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘              
  ↘↘↘↘↘↘↘↘↘↘↘↘           ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↓            NATS Backup
 ↘↘↘↘↘↘↘↘↘↘↘            ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘           #built at#
  ↘↘↘↘↘↘↘↘↘↘↘↘           ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↖            
    ↘↘↘↘↘↘↘↘↘↘↘↘           ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘              
      ↘↘↘↘↘↘↘↘↘↘↘↙           ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘                
        ↘↘↘↘↘↘↘↘↘↘↘↖           ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘                  
         ↙↘↘↘↘↘↘↘↘↘↘↘           ↖↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘                    
           ↘↘↘↘↘↘↘↘↘↘↘↘           ↙↘↘↘↘↘↘↘↘↘↘↘↘↘                      
             ↘↘↘↘↘↘↘↘↘↘↘↘           ↘↘↘↘↘↘↘↘↘↘↙                       
               ↘↘↘↘↘↘↘↘↘↘↘↓           ↘↘↘↘↘↘↘                         
                 ↘↘↘↘↘↘↘↘↘↘↘↙           ↘↘↘                           
                   ↘↘↘↘↘↘↘↘↘↘↘                                        
                    ↘↘↘↘↘↘↘↘↘↘↘↘                                      
                      ↘↘↘↘↘↘↘↘↘↘↘↘                                    
                        ↘↘↘↘↘↘↘↘↘↘↘↙                                  
                          ↘↘↘↘↘↘↘↘                                    
                            ↘↘↘↘                                      
                             ↙←                                       
EOF

echo "${ENCRYPTION_PASSWORD?Error: env-var is not set}" >/dev/null
echo "${BACKUP_DIR?Error: env-var is not set}" >/dev/null
echo "${NATS_URL?Error: env-var is not set}" >/dev/null

# other required vars in above format

TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
TMP_BACKUP_DIR="/tmp/backup_$TIMESTAMP"

mkdir -p "$BACKUP_DIR" "$TMP_BACKUP_DIR"

debug() {
  if [ "${DEBUG:-false}" == "true" ]; then
    echo "$@"
  fi
}

archive() {
  tar cf "$2" -C "$(dirname $1)" "$1"
}

encrypt() {
  openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -in "$1" -out "$2" -pass pass:"$ENCRYPTION_PASSWORD"
}

compress() {
  zstd --rm "$1" -o "$2"
}

debug "taking nats backup"
nats account backup --server="$NATS_URL" "$TMP_BACKUP_DIR" -f

debug "bundling backups as an archive"
archive "${TMP_BACKUP_DIR}" "${TMP_BACKUP_DIR}.tar"

debug "compressing backup archive"
compress "${TMP_BACKUP_DIR}.tar" "${TMP_BACKUP_DIR}.tar.zst"

debug "encrypting compressed backup archive"
encrypt "$TMP_BACKUP_DIR.tar.zst" "$TMP_BACKUP_DIR.tar.zst.enc"

debug "copying result to backup dir"
cp "$TMP_BACKUP_DIR.tar.zst.enc" "$BACKUP_DIR"

all_backups=$(ls -t "$BACKUP_DIR")

MAX_NUM_BACKUPS=${MAX_NUM_BACKUPS:-10}

idx=1
for backup in $all_backups; do
  if [ $idx -gt $((MAX_NUM_BACKUPS)) ]; then
    rm -rf "${BACKUP_DIR:?}/$backup"
  fi
  idx=$((idx + 1))
done

echo "Backup Complete."
