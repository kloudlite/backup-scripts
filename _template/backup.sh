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

# other required vars in above format

TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
TMP_BACKUP_DIR="/tmp/backup_$TIMESTAMP"

mkdir -p "$BACKUP_DIR" "$TMP_BACKUP_DIR"

debug() {
  # [ "${DEBUG:-false}" == "true" ] && echo "$@" # throws non-zero exit code, if DEBUG is not set

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

# TODO: take backup

# TODO: convert to tar if multiple files
# tar cf "${TMP_BACKUP_DIR}.tar" "${TMP_BACKUP_DIR}"

# TODO: compress with zstd

# TODO: encrypt with encrypt()

# TODO: copy result to backup dir

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
