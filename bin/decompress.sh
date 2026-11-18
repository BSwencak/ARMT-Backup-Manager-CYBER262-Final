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


#Function to select .backup.tgz to decompress
SELECT_BACKUP(){
  CHOICE=-1
  
  #Checks if there are any .backup.tgz, returns if not
  if ! find "$AIRPORT_PATH" -maxdepth 1 -type f \( -name "*.backup.tgz" \) | grep -q .; then
      clear
      LOG "No .backup.tgz files found — user returned to main menu"
      echo -e "${BOLD_BLUE}$FAAID${BOLD_RED} has no compressed backup files.${NC}"
      bash "main.sh" $FAAID
  fi

  #Runs while choice is incorrect
  while ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 0 || CHOICE > ${#BACKUPS[@]}+1 )); do
      #Loads .backup.tgz into array
      mapfile -t BACKUPS < <(
      find "$AIRPORT_PATH" -maxdepth 1 -type f -name "*.backup.tgz" -printf "%f\n" \
      | sort -r
      )

      echo -e "\nSelect a backup to compress: "
      for i in "${!BACKUPS[@]}"; do
          echo "$((i+1)): ${BACKUPS[$i]}"
      done
      GO_BACK=$(( ${#BACKUPS[@]} + 1 )) #Calculates GO_BACK based on entries listed
      echo -e "$GO_BACK: Go Back\n0: Exit"

      read -p $'\nEnter choice: ' CHOICE
  done

  #Exits if user chooses 0
  if [[ $CHOICE -eq 0 ]]; then
      LOG "User exited decompress menu"
      exit 0
  #Returns to main if user chooses number assigned to GO_BACK
  elif [[ $CHOICE -eq $GO_BACK ]]; then
      LOG "User returned to main menu from decompress menu"
      clear
      bash "main.sh" $FAAID
  fi
  
  #Figures out BACKUP_FILE based on choice
  FILE_NAME="${BACKUPS[$((CHOICE-1))]}"
  LOG "User selected $FILE_NAME for decompression"
}


#Function for compressing the .backup.tgz
DECOMPRESS_BACKUP(){
  LOG "Attempting to decompress $FILE_NAME"

  #Logs and outputs status of decompression
  if tar -xzf "$AIRPORT_PATH/$FILE_NAME" -C "$AIRPORT_PATH"; then
      LOG "Successfully decompressed $FILE_NAME"
      clear
      echo -e "${YELLOW}Backup $FILE_NAME Decompressed${NC}"
  else
      LOG "ERROR: Failed to decompress $FILE_NAME"
      clear
      echo -e "${BOLD_RED}Decompression failed for $FILE_NAME${NC}"
  fi
}


SELECT_BACKUP
DECOMPRESS_BACKUP

bash "main.sh" $FAAID