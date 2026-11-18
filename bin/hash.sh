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


#Function to select .backup to creat hash for
SELECT_BACKUP(){
  CHOICE=-1
  
  #Checks if there are any .backup, returns if not
  if ! find "$AIRPORT_PATH" -maxdepth 1 -type f \( -name "*.backup" \) | grep -q .; then
      clear
      echo "${BOLD_BLUE}$FAAID${BOLD_RED} has no backup files. ${YELLOW}Returning . . .${NC}"
      LOG "No .backup files found — user returned to main menu"
      bash "main.sh" $FAAID
  fi
  
  #Runs while choice is incorrect
  while ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 0 || CHOICE > ${#BACKUPS[@]}+1 )); do
      #Loads .backup into array
      mapfile -t BACKUPS < <(
      find "$AIRPORT_PATH" -maxdepth 1 -type f -name "*.backup" -printf "%f\n" \
      | sort -r
      )


      echo -e "\nSelect a backup to create a hash of: "
      for i in "${!BACKUPS[@]}"; do
          echo "$((i+1)): ${BACKUPS[$i]}"
      done
      GO_BACK=$(( ${#BACKUPS[@]} + 1 )) #Calculates GO_BACK based on entries listed
      echo -e "$GO_BACK: Go Back\n0: Exit"
      read -p $'\nEnter choice: ' CHOICE
  done
}


#Function for creating hash
CREATE_HASH(){
  BACKUP_FILE="${BACKUPS[$((CHOICE-1))]}"   #Figures out BACKUP_FILE based on choice
  LOG "User selected $BACKUP_FILE for hashing"
  #CREATES SHA256 CHECKSUM HASH OF TXT FILE FOR AIRPORT
  cat "$AIRPORT_PATH/$BACKUP_FILE" | sha256sum > "$AIRPORT_PATH/$BACKUP_FILE.sha256"
  clear
  echo -e "${BLUE}Hash for $BACKUP_FILE Created: ${NC}"
  cat "$AIRPORT_PATH/$BACKUP_FILE.sha256"
  LOG "Successfully created hash for $BACKUP_FILE"  
}


SELECT_BACKUP

#Exits if user chooses 0
if [[ $CHOICE -eq 0 ]]; then
	exit 0
#Returns to main if user chooses number assigned to GO_BACK
elif [[ $CHOICE -eq $GO_BACK ]]; then
	clear
	bash "main.sh" $FAAID
#Otherwise, runs hashing proccess
else
	CREATE_HASH
fi

bash "main.sh" $FAAID

