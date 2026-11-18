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


#Function to select .backup to compress
SELECT_BACKUP(){
  CHOICE=-1
  
  #Checks if there are any .backups, returns if not
  if ! find "$AIRPORT_PATH" -maxdepth 1 -type f \( -name "*.backup" \) | grep -q .; then
      clear
      echo "${BOLD_BLUE}$FAAID${BOLD_RED} has no backup files.${NC}"
      LOG "No .backup files found — user returned to main menu"
      bash "main.sh" $FAAID
  fi

  #Runs while choice is incorrect
  while ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 0 || CHOICE > ${#BACKUPS[@]}+1 )); do
      #Loads .backups into array
      mapfile -t BACKUPS < <(
      find "$AIRPORT_PATH" -maxdepth 1 -type f -name "*.backup" -printf "%f\n" \
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
  	  clear
      LOG "User exited compression menu"
      exit 0
  #Returns to main if user chooses number assigned to GO_BACK
  elif [[ $CHOICE -eq $GO_BACK ]]; then
      clear
      LOG "User returned to main menu from compression menu"
      bash "main.sh" $FAAID
      exit 0
  fi
  
  #Figures out BACKUP_FILE based on choice
  BACKUP_FILE="${BACKUPS[$((CHOICE-1))]}"
  LOG "User selected $BACKUP_FILE for compression"
}


#Function for compressing the .backup
COMPRESS_BACKUP(){

  #Takes input while current input is invalid
  if [[ ! "$ANSWER" =~ ^[yYnN]$ ]]; then
      read -p "$(echo -e "Would you like to include hash in the compression (if one does not exist one will be created) (y/n)?: ")" ANSWER
  fi

  #Validates proper input, returns if wrong
  if [[ ! "$ANSWER" =~ ^[yYnN]$ ]]; then
      clear
      echo -e "\n${BOLD_RED}Incorrect Input, ${YELLOW}returning. . .${NC}"
      LOG "Invalid input for hash inclusion prompt"
      SELECT_BACKUP
      return
  fi

  #If option to include hash is YES
  if [[ "$ANSWER" =~ ^[yY]$ ]]; then
      LOG "User chose to include hash in compression for $BACKUP_FILE"
	
      #Checks if hash already exists
      if [[ -f "$AIRPORT_PATH/$BACKUP_FILE.sha256" ]]; then
          clear
          echo -e "${BOLD_YELLOW}Hash already exists for this backup, continuing.${NC}"
          LOG "Hash already existed for $BACKUP_FILE"
      #Creates hash if one does not exist for compression
      else
          clear
          echo -e "${BOLD_GREEN}Creating new hash...${NC}"
          #Checks and logs if error/success in creating hash
          if cat "$AIRPORT_PATH/$BACKUP_FILE" | sha256sum > "$AIRPORT_PATH/$BACKUP_FILE.sha256"; then
              LOG "Created new hash for $BACKUP_FILE"
          else
              LOG "ERROR: Failed to create hash for $BACKUP_FILE"
          fi
      fi

	  #Checks and logs if error/success in compressing backup with hash and outputs if successful
      if tar -czf "$AIRPORT_PATH/$BACKUP_FILE.tgz" -C "$AIRPORT_PATH" "$BACKUP_FILE" "$BACKUP_FILE.sha256"; then
          LOG "Compressed $BACKUP_FILE with hash included"
          echo -e "\n${GREEN}$FAAID Folder Compressed with Hash:${NC} $BACKUP_FILE"
          echo -e "${BLUE}Hash for $BACKUP_FILE Created: ${NC}"
          cat "$AIRPORT_PATH/$BACKUP_FILE.sha256"
      else
          LOG "ERROR: Failed to compress $BACKUP_FILE with hash"
          bash "main.sh" $FAAID
          exit 0
      fi

  #If user chooses to compress without hash
  else
      LOG "User chose NOT to include hash in compression for $BACKUP_FILE"

      clear
      
	  #Checks and logs if error/success in compressing backup without hash and outputs if successful
      if tar -czf "$AIRPORT_PATH/$BACKUP_FILE.tgz" -C "$AIRPORT_PATH" "$BACKUP_FILE"; then
          LOG "Compressed $BACKUP_FILE without hash"
          echo -e "\n${GREEN}$FAAID Folder Compressed:${NC} $BACKUP_FILE"
      else
          LOG "ERROR: Failed to compress $BACKUP_FILE without hash"
          bash "main.sh" $FAAID
          exit 0
      fi
  fi
}


SELECT_BACKUP
COMPRESS_BACKUP

bash "main.sh" $FAAID