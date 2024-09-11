#!/bin/bash
##########################################################################################################
# Summary:
# 	This script is used for generating GIT changes.
##########################################################################################################
# Helpers
GREEN='\033[92m'
RED='\033[91m'
NC='\033[0m'
CYAN='\033[96m'
YELLOW='\033[93m'
TICK="[${GREEN}✓${NC}]"
CROSS="[${RED}✗ ${NC}]"
INFO="[${CYAN}i${NC}]"
ALERT="[${YELLOW}⚠ ${NC}]"

init(){
    # get our origin branch
    BRANCH=$(git branch -l master main)
    if [ -z "$1" ]
    then 
        # get diff stats ignoring tests matching 'should' and 'test'
        IGNORETESTS=1
        STATS=$(git diff --shortstat $BRANCH ':!*Should*' ':!*Test*' ':!*Migrations*')
    elif [ "$1" == "test" ]
    then
        IGNORETESTS=0
        STATS=$(git diff --shortstat $BRANCH)
    else 
        IGNORETESTS=1
        BRANCH=$1
        STATS=$(git diff --shortstat $BRANCH ':!*Should*' ':!*Test*' ':!*Migrations*')
    fi
    FILECHANGES=0
    INSERTIONS=0
    DELETIONS=0
}

getIndividualStats() {
    IFS=',' read -ra STAT <<< "$STATS"
    for i in "${STAT[@]}"; do
        if [[ $i == *"changed"* ]]; then
            FILECHANGES=$(echo $i | cut -d' ' -f1)
        elif [[ $i == *"insertion"* ]]; then
            INSERTIONS=$(echo $i | cut -d' ' -f1)
        elif [[ $i == *"deletion"* ]]; then
            DELETIONS=$(echo $i | cut -d' ' -f1)
        fi
    done
}

showAllStats() {
    echo -e "${INFO} ${CYAN}Files Changed: ${NC} ${FILECHANGES}"
    echo -e "${INFO} ${CYAN}Insertions: ${NC} ${INSERTIONS}"
    echo -e "${INFO} ${CYAN}Deletions: ${NC} ${DELETIONS}"
}

gradeFileChanges() {
    echo -e "File change calculations:"
    if [[ $FILECHANGES -gt 50 ]]; then
        echo -e "${CROSS} ${RED}${FILECHANGES} file(s) changed${NC}. Consider splitting up your PR."
    elif [[ $FILECHANGES -gt 10 ]]; then
        echo -e "${ALERT} ${YELLOW}PR looking good. Potential for reducing (${FILECHANGES}) file changes.${NC}"
    else
        echo -e "${TICK} ${GREEN}PR is great! Nice work!${NC}"
    fi
    echo "-----------------------------------------------"
}
gradeCodeChanges() {
    echo -e "Line change calculations (may not be accurate):"
    TOTALCHANGES=$(($INSERTIONS + $DELETIONS))
    if [[ $TOTALCHANGES -gt 500 ]]; then
        echo -e "${CROSS} ${RED}${TOTALCHANGES} lines changed${NC}. Consider splitting up your PR."
        echo -e "NOTE: This number is the sum of insertions (${GREEN}${INSERTIONS}${NC}) and deletions (${RED}${DELETIONS}${NC})."
    elif [[ $TOTALCHANGES -gt 100 ]]; then
        echo -e "${ALERT} ${YELLOW}PR looking good. Potential for reducing file changes.${NC}"
    else
        echo -e "${TICK} ${GREEN}PR is good to go!${NC}"
    fi
}

brandonGradeTotal() {
    if [[ $TOT_COUNT -gt 500 ]]; then
        BRANDON_GRADE="${RED}F"
    elif [[ $TOT_COUNT -gt 100 ]]; then
        BRANDON_GRADE="${YELLOW}C"
    elif [[ $TOT_COUNT -gt 50 ]]; then
        BRANDON_GRADE="${CYAN}B"
    else
        BRANDON_GRADE="${GREEN}A"
    fi
     BRANDON_GRADE="$BRANDON_GRADE - $TOT_COUNT Changes ($MOD_COUNT modified, $ADD_COUNT added, $REM_COUNT removed)${NC}"
}

brandonGrading() {
    MOD_PATTERN='^.+(\[-|\{\+).*$'
    ADD_PATTERN='^\{\+.*\+\}$'
    REM_PATTERN='^\[-.*-\]$'
    SUMMARY=$(git diff --word-diff --unified=0 $BRANCH ':!*Should*' ':!*Test*' ':!*Migrations*' | sed -nr -e "s/$MOD_PATTERN/modified/p" -e "s/$ADD_PATTERN/added/p" -e "s/$REM_PATTERN/removed/p" | sort | uniq -c)
    MOD_COUNT=$(echo $SUMMARY | grep -oP '\S+(?= modified)')
    ADD_COUNT=$(echo $SUMMARY | grep -oP '\S+(?= added)')
    REM_COUNT=$(echo $SUMMARY | grep -oP '\S+(?= removed)')

    # check if counts weren't found
    if [ -z "$MOD_COUNT" ]; then
        MOD_COUNT=0
    fi
    if [ -z "$ADD_COUNT" ]; then
        ADD_COUNT=0
    fi
    if [ -z "$REM_COUNT" ]; then
        REM_COUNT=0
    fi

    TOT_COUNT=$(($MOD_COUNT + $ADD_COUNT + $REM_COUNT))
    brandonGradeTotal
    echo "-----------------------------------------------"
    echo -e "Brandon's grading: "
    echo -e $BRANDON_GRADE
}


gradeMyPR() {
    init $1
    help
    getIndividualStats
    gradeFileChanges
    gradeCodeChanges
    brandonGrading
}

help() {
    echo -e "${CYAN}--------------------------------------------------------------------
Welcome to Change Summary! This script will help grade the initial status of the PR.
Please note that some of the calculations may not 100% accurate.${NC}";
    if [ $IGNORETESTS -eq 1 ]; then
        echo -e "${INFO} ${CYAN}Ignoring test files and migrations${NC}" 
    else
        echo -e "${INFO} ${CYAN}Including test files${NC}"
    fi
    echo -e "${CYAN}--------------------------------------------------------------------${NC}"
}

gradeMyPR