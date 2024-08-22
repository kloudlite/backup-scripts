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
  ↘↘↘↘↘↘↘↘↘↘↘↘           ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↓            MongoDB Backup
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

echo "${MONGODB_URI?Error: env-var is not set}" >/dev/null

TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
TMP_BACKUP_DIR="/tmp/backup_$TIMESTAMP"

mkdir -p "$BACKUP_DIR" "$TMP_BACKUP_DIR"

debug() {
  if [ "${DEBUG:-false}" == "true" ]; then
    echo "$@"
  fi
}

# archives, converts $1 to a tar archive ($2)
archive() {
  tar cf "$2" -C "$(dirname $1)" "$1"
}

encrypt() {
  openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -in "$1" -out "$2" -pass pass:"$ENCRYPTION_PASSWORD"
}

compress() {
  zstd --rm "$1" -o "$2"
}

debug "taking backup"
mongodump --uri="${MONGODB_URI}" --archive="${TMP_BACKUP_DIR}" --dumpDbUsersAndRoles --gzip

debug "archiving backup"
archive "${TMP_BACKUP_DIR}" "${TMP_BACKUP_DIR}.tar"

debug "compressing with zstd"
compress "${TMP_BACKUP_DIR}.tar" "${TMP_BACKUP_DIR}.tar.zst"

debug "encrypting with openssl"
encrypt "$TMP_BACKUP_DIR.tar.zst" "$TMP_BACKUP_DIR.tar.zst.enc"

debug "copying result to backup dir"
cp "$TMP_BACKUP_DIR.tar.zst.enc" "$BACKUP_DIR"

pushd "$BACKUP_DIR"

all_backups=$(ls -t)

MAX_NUM_BACKUPS=${MAX_NUM_BACKUPS:-10}

debug "cleaning up old backups (> $MAX_NUM_BACKUPS) if any"
idx=1
for backup in $all_backups; do
  if [ $((idx)) -gt $((MAX_NUM_BACKUPS)) ]; then
    debug "removing old backup $backup"
    rm "${BACKUP_DIR:?}/$backup"
  fi
  idx=$((idx + 1))
done

popd

echo "Backup Complete."
