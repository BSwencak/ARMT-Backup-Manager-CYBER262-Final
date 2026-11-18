#!/bin/bash
FAAID=$1 #Imported ARG for FAA IDENTIFIER
AIRPORT_PATH="/DATA/Documents/PSU/CYBER_262/ARMTBackups/backups/${FAAID}" #Full Airport Path

#Text Formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_BLUE='\033[1;34m'
BOLD_YELLOW='\033[1;33m'
NC='\033[0m'

#Function for Logging
LOG(){
  local MESSAGE="$1"
  local LOGFILE="$AIRPORT_PATH/log/${FAAID}_LOG.txt"
  local TIMESTAMP
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$TIMESTAMP] $MESSAGE" >> "$LOGFILE"
}


#Function for choosing backup to verify
SELECT_BACKUP(){
  CHOICE=-1

  # Check if any valid pairs exist to verify
  valid_pairs=0
  for file in "$AIRPORT_PATH"/*.backup; do
      [[ -e "$file" ]] || break
      if [[ -f "$file.sha256" ]]; then
          valid_pairs=1
      fi
  done

  #If there are no valid pairs, returns
  if (( valid_pairs == 0 )); then
      clear
      LOG "No valid backup/hash pairs found for $FAAID"
      echo -e "${BOLD_BLUE}$FAAID${BOLD_RED} has no valid backup + hash pairs.${NC}"
      bash "main.sh" "$FAAID"
      exit 0
  fi

  #Load only backups that have a matching .sha256 to array
  mapfile -t BACKUPS < <(
  for f in "$AIRPORT_PATH"/*.backup; do
      [[ -e "$f" ]] || continue
      if [[ -f "$f.sha256" ]]; then
          printf "%s\n" "$(basename "$f")"
      fi
  done | sort -r
      )

  #Runs while input incorrect
  while ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 0 || CHOICE > ${#BACKUPS[@]}+1 )); do
      echo -e "\nSelect a backup that has a hash to create new hash of for verification:"

      for i in "${!BACKUPS[@]}"; do
          echo "$((i+1)): ${BACKUPS[$i]}"
      done

      GO_BACK=$(( ${#BACKUPS[@]} + 1 )) #Calculates GO_BACK based on entries listed
      echo -e "$GO_BACK: Go Back\n0: Exit"

      read -p $'\nEnter choice: ' CHOICE
  done

  #Exits if chosen
  if [[ $CHOICE -eq 0 ]]; then
      LOG "User exited Verify Hash menu"
      exit 0
  #Goes back if chosen
  elif [[ $CHOICE -eq $GO_BACK ]]; then
      LOG "User returned to main menu from Verify Hash menu"
      clear
      bash "main.sh" "$FAAID"
      exit 0
  fi

  #Figures out BACKUP_FILE based on choice
  BACKUP_FILE="${BACKUPS[$((CHOICE-1))]}"
  LOG "User selected $BACKUP_FILE for hash verification"
}


#Function for verifying the hash
VERIFY_HASH(){
  LOG "Starting hash verification for $BACKUP_FILE"

  clear
  cat "$AIRPORT_PATH/$BACKUP_FILE" | sha256sum > "$AIRPORT_PATH/CHECK_HASH_${BACKUP_FILE}.sha256"

  echo -e "${BLUE}Check Hash for $BACKUP_FILE Created: ${NC}"
  cat "$AIRPORT_PATH/CHECK_HASH_$BACKUP_FILE.sha256"

  echo -e "${BLUE}Original Hash for $BACKUP_FILE: ${NC}"
  cat "$AIRPORT_PATH/$BACKUP_FILE.sha256"

  #Checks and logs if file verified or not from compared hashes
  if cmp -s "$AIRPORT_PATH/$BACKUP_FILE.sha256" "$AIRPORT_PATH/CHECK_HASH_${BACKUP_FILE}.sha256"; then
      echo -e "${BOLD_GREEN}BACKUP UNCHANGED AND SUCCESSFULLY COMPLETED${NC}"
      LOG "Hash verification SUCCESS for $BACKUP_FILE — backup unchanged"
  else
      echo -e "${BOLD_RED}The files have been altered in backup. BACKUP INCOMPLETE${NC}"
      LOG "Hash verification FAILED for $BACKUP_FILE — backup altered"
  fi
}

SELECT_BACKUP
VERIFY_HASH

bash "main.sh" "$FAAID"