#!/bin/bash
CHECK=$1 #Imported ARG for FAA IDENTIFIER to check if returning
BACKUP_DIR="/DATA/Documents/PSU/CYBER_262/ARMTBackups/backups"
BIN_DIR="/DATA/Documents/PSU/CYBER_262/ARMTBackups/bin"

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

FUNCTION=100

#Function for selecting airport
SELECT_AIRPORT(){
  CHOICE=-1
  #Runs while input is incorrect
  while ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 0 || CHOICE > ${#AIRPORTS[@]}+1 )); do
  	  #Puts airports into an array
      mapfile -t AIRPORTS < <(ls -1 "$BACKUP_DIR")
      echo -e "\nARMT Backup Manager, Select an airport to work in:"
	
      #Lists airport
      for i in "${!AIRPORTS[@]}"; do
          echo "$((i+1)): ${AIRPORTS[$i]}"
      done

      echo -e "0: Exit"

      read -p $'\nEnter choice: ' CHOICE
      clear
      
      #Validates proper input
      if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 0 || CHOICE > ${#AIRPORTS[@]} )); then
          clear
          echo -e "${BOLD_RED}Invalid choice. Try again.${NC}"
          continue
      fi
  done

  if [[ $CHOICE -eq 0 ]]; then
      exit 0
  fi
  FAAID="${AIRPORTS[$((CHOICE-1))]}" #Gets FAAID based on choice
}


#Function for choosing Airport backup manager function
SELECT_FUNCTION(){
  FUNCTION=-1
  AIRPORT_PATH="/DATA/Documents/PSU/CYBER_262/ARMTBackups/backups/$FAAID"

  #Checks that airport directory has files
  if ! ( find "$AIRPORT_PATH" -maxdepth 1 -type f \( -name "*.backup" -o -name "*.backup.tgz" -o -name "*.backup.sha256" \) | grep -q . ) \
     && ! ( find "$AIRPORT_PATH/secure" -maxdepth 1 -type f | grep -q . ); then
      clear
      echo "$FAAID has no backup files."
      SELECT_AIRPORT
      SELECT_FUNCTION
  fi

  #Runs while input incorrect
  while [[ $FUNCTION -lt 0 || $FUNCTION -gt 8 ]]; do
      echo -e "\nChoose a function to perform on an ${BOLD_BLUE}$FAAID${NC} backup, choose option:\n1: Create Hash\n2: Compress Backup\n3: Decompress Backup\n4: Encrypt Backup\n5: Decrypt Backup\n6: Verify Backup\n7: Clear Excess\n8: Go Back\n0: Exit"
      read -p $'\nEnter Function Choice: ' FUNCTION
      clear

      if [[ $FUNCTION -eq 1 ]]; then
          FUNCTION_NAME="create hash"
          bash "hash.sh" $FAAID

      elif [[ $FUNCTION -eq 2 ]]; then
          FUNCTION_NAME="compress backup"
          bash "compress.sh" $FAAID

      elif [[ $FUNCTION -eq 3 ]]; then
          FUNCTION_NAME="decompress backup"
          bash "decompress.sh" $FAAID

      elif [[ $FUNCTION -eq 4 ]]; then
          FUNCTION_NAME="encrypt backup"
          bash "encrypt.sh" $FAAID

      elif [[ $FUNCTION -eq 5 ]]; then
          FUNCTION_NAME="decrypt backup"
          bash "decrypt.sh" $FAAID

      elif [[ $FUNCTION -eq 6 ]]; then
          FUNCTION_NAME="verify backup"
          bash "verify.sh" $FAAID

      elif [[ $FUNCTION -eq 7 ]]; then
          FUNCTION_NAME="clear excess"
          bash "clear.sh" $FAAID

	  #Goes back to airport choice if chosen
      elif [[ $FUNCTION -eq 8 ]]; then
          CHOICE=-1
          SELECT_AIRPORT
          SELECT_FUNCTION
          return
      #Exits program if chosen
      elif [[ $FUNCTION -eq 0 ]]; then
          exit 0
      else
          echo -e "${BOLD_RED}Invalid choice. Try again.${NC}"
          clear
      fi

  done
}


#Checks which menu to go to based on if returning from airport or not
if [[ -n "$CHECK" && -d "$BACKUP_DIR/$CHECK" ]]; then
	#Goes to functions for that airport
    FAAID=$CHECK
    SELECT_FUNCTION
else
	clear
    SELECT_AIRPORT
    SELECT_FUNCTION
fi

