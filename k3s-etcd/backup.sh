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
  ↘↘↘↘↘↘↘↘↘↘↘↘           ↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↘↓            EtcD Backup
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
echo "${SNAPSHOTS_DIR?Error: env-var is not set}" >/dev/null

TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
TMP_BACKUP_DIR="/tmp/backup_$TIMESTAMP"

mkdir -p "$BACKUP_DIR" "$TMP_BACKUP_DIR"

debug() {
  if [ "${DEBUG:-false}" == "true" ]; then
    echo "$@"
  fi
}

encrypt() {
  openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -in "$1" -out "$2" -pass pass:"$ENCRYPTION_PASSWORD"
}

compress() {
  zstd --rm "$1" -o "$2"
}

debug "copying k3s etcd snapshots"
[ -d "$SNAPSHOTS_DIR" ] || (echo "SNAPSHOTS_DIR ($SNAPSHOTS_DIR) does not exist, exiting." && exit 1)
cp "$SNAPSHOTS_DIR"/* "$TMP_BACKUP_DIR"

debug "compressing, and encrypting k3s etcd snapshots"
for snapshot in "$TMP_BACKUP_DIR"/*; do
  compress "$snapshot" "$snapshot.zst"
  encrypt "$snapshot.zst" "$snapshot.zst.enc"
done

debug "copying result to backup dir"
cp "$TMP_BACKUP_DIR"/*.zst.enc "$BACKUP_DIR"

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
