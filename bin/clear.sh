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


#Function to select encrypted backups to clear excess of
SELECT_BACKUP(){
  CHOICE=-1
  
  #Checks if there are any encrypted backups, returns if not
  if ! ( find "$AIRPORT_PATH/secure" -maxdepth 1 -type f -name "*.backup.tgz.aes256" | grep -q . ); then
      clear
      LOG "No encrypted backups found — user returned to main menu"
      echo -e "${BOLD_BLUE}$FAAID${BOLD_RED} has no encrypted backup files.${NC}"
      bash "main.sh" "$FAAID"
  fi

  #Runs while choice is incorrect
  while ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 0 || CHOICE > ${#BACKUPS[@]}+1 )); do
      #Loads encrypted backups into array
      mapfile -t BACKUPS < <(
      find "$AIRPORT_PATH/secure" -maxdepth 1 -type f -name "*.backup.tgz.aes256" -printf "%f\n" \
      | sort -r
      )

	  #Lists all encrypted backups available to clear excess of
      echo -e "\nSelect an encrypted backup to clean excess files of: "
      for i in "${!BACKUPS[@]}"; do
          echo "$((i+1)): ${BACKUPS[$i]}"
      done
      GO_BACK=$(( ${#BACKUPS[@]} + 1 )) #Calculates GO_BACK based on entries listed
      echo -e "$GO_BACK: Go Back\n0: Exit"
      read -p $'\nEnter choice: ' CHOICE
  done

  #Exits if user chooses 0
  if [[ $CHOICE -eq 0 ]]; then
      LOG "User exited Clear Excess menu"
      exit 0
  #Returns to main if user chooses number assigned to GO_BACK
  elif [[ $CHOICE -eq $GO_BACK ]]; then
      LOG "User returned to main menu from Clear Excess menu"
      clear
      bash "main.sh" $FAAID
  fi
  
  #Figures out FILE_NAME based on choice
  FILE_NAME="${BACKUPS[$((CHOICE-1))]}"
  
  #Removes .aes256
  BASE_NO_AES="${FILE_NAME%.aes256}"	# > ABC20260421.backup.tgz
  
  #Removes .tgz to get original .backup
  BASE_BACKUP="${BASE_NO_AES%.tgz}"		# > ABC20260421.backup
  
  #Build hash filename
  BASE_HASH="${BASE_BACKUP}.sha256"		# > ABC20260421.backup.sha256
  
  LOG "User selected $FILE_NAME for excess cleanup"
}


#Function to clear the excess if it exists for the encrypted backup
CLEAR_EXCESS() {
  clear
  echo -e "${BOLD_YELLOW}Cleaning excess files for $BASE_BACKUP...${NC}"
  LOG "Starting excess cleanup for $BASE_BACKUP"

  #Deletes decrypted .backup
  if [[ -f "$AIRPORT_PATH/$BASE_BACKUP" ]]; then
      rm -f "$AIRPORT_PATH/$BASE_BACKUP"
      LOG "Removed decrypted file: $BASE_BACKUP"
  fi

  #Deletes decompressed .backup.tgz
  if [[ -f "$AIRPORT_PATH/$BASE_NO_AES" ]]; then
      rm -f "$AIRPORT_PATH/$BASE_NO_AES"
      LOG "Removed decompressed file: $BASE_NO_AES"
  fi

  #Deletes hash file
  if [[ -f "$AIRPORT_PATH/$BASE_HASH" ]]; then
      rm -f "$AIRPORT_PATH/$BASE_HASH"
      LOG "Removed hash file: $BASE_HASH"
  fi

  #Deletes CHECK_HASH file
  if [[ -f "$AIRPORT_PATH/CHECK_HASH_$BASE_BACKUP.sha256" ]]; then
      rm -f "$AIRPORT_PATH/CHECK_HASH_$BASE_BACKUP.sha256"
      LOG "Removed check-hash file: CHECK_HASH_$BASE_BACKUP.sha256"
  fi

  LOG "Completed excess cleanup for $BASE_BACKUP"
  echo -e "${BOLD_GREEN}Excess files cleared.${NC}"
}


SELECT_BACKUP
CLEAR_EXCESS

bash "main.sh" $FAAID