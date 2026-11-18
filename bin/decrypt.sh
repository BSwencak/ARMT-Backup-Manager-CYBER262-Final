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

#ENV passfile path
ENV="/DATA/Documents/PSU/CYBER_262/ARMTBackups/env"


#Function for Logging
LOG(){
  local MESSAGE="$1"
  local LOGFILE="$AIRPORT_PATH/log/${FAAID}_LOG.txt"
  local TIMESTAMP
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$TIMESTAMP] $MESSAGE" >> "$LOGFILE"
}


#Function to select .backup.tgz.aes256 to decrypt
SELECT_BACKUP(){
  CHOICE=-1
  
  #Checks if there are any .backup.tgz.aes256, returns if not
  if ! find "$AIRPORT_PATH/secure" -maxdepth 1 -type f \( -name "*.backup.tgz.aes256" \) | grep -q .; then
      clear
      LOG "No encrypted backups found — user returned to main menu"
      echo -e "${BOLD_BLUE}$FAAID${BOLD_RED} has no encrypted backup files.${NC}"
      bash "main.sh" $FAAID
  fi

  #Runs while choice is incorrect
  while ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 0 || CHOICE > ${#BACKUPS[@]}+1 )); do
      #Loads .backup.tgz.aes256 into array
      mapfile -t BACKUPS < <(
      find "$AIRPORT_PATH/secure" -maxdepth 1 -type f -name "*.backup.tgz.aes256" -printf "%f\n" \
      | sort -r
      )


      echo -e "\nSelect a backup to decrypt: "
      for i in "${!BACKUPS[@]}"; do
          echo "$((i+1)): ${BACKUPS[$i]}"
      done
      GO_BACK=$(( ${#BACKUPS[@]} + 1 )) #Calculates GO_BACK based on entries listed
      echo -e "$GO_BACK: Go Back\n0: Exit"

      read -p $'\nEnter choice: ' CHOICE
  done

  #Exits if user chooses 0
  if [[ $CHOICE -eq 0 ]]; then
      LOG "User exited decrypt menu"
      exit 0
  #Returns to main if user chooses number assigned to GO_BACK
  elif [[ $CHOICE -eq $GO_BACK ]]; then
      LOG "User returned to main menu from decrypt menu"
      clear
      bash "main.sh" $FAAID
  fi
  
  #Figures out FILE_NAME based on choice
  FILE_NAME="${BACKUPS[$((CHOICE-1))]}"
  
  #Removes .aes256
  FILE_BASE="${FILE_NAME%.aes256}" # > ABC20260421.backup.tgz

  LOG "User selected encrypted file $FILE_NAME for decryption"
}

#Function for decrypting backup
DECRYPT_BACKUP(){
  LOG "Attempting to decrypt $FILE_NAME"

  #Logs and outputs status of decompression
  if openssl enc -aes-256-cbc -d -salt -pbkdf2 -in "$AIRPORT_PATH/secure/$FILE_NAME" -out "$AIRPORT_PATH/$FILE_BASE" -pass file:"$ENV/aes_password.passfile"; then
      LOG "Successfully decrypted $FILE_NAME > $FILE_BASE"
      clear
      echo -e "${YELLOW}Backup $FILE_NAME Decrypted${NC}"
  else
      LOG "ERROR: Failed to decrypt $FILE_NAME"
      clear
      echo -e "${BOLD_RED}Decryption failed for $FILE_NAME${NC}"
  fi
}


SELECT_BACKUP
DECRYPT_BACKUP

bash "main.sh" $FAAID