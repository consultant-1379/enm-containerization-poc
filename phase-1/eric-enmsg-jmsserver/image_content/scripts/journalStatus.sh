#!/bin/bash

_MV='/bin/mv -f'

_TAR='/bin/tar -cf'

_MKDIR=/bin/mkdir

_RM='rm -rf'

if [ -z "$JBOSS_HOME" ]; then
    JBOSS_HOME=/ericsson/3pp/jboss
fi
export JBOSS_HOME


# Source jms logger methods
. $JBOSS_HOME/bin/jmslogger

JBOSS_MESSAGING_DATA_DIRECTORY=/ericsson/jms/data
export JBOSS_MESSAGING_DATA_DIRECTORY

JOURNAL_TAR=$JBOSS_MESSAGING_DATA_DIRECTORY/"hornetq_journals_"$(date +%Y%m%d_%H%M%S).tar
export JOURNAL_TAR


if [ -z "$JOURNALS_MOVING_LOCK_FILE" ]; then
    JOURNALS_MOVING_LOCK_FILE="$JBOSS_MESSAGING_DATA_DIRECTORY/journals.moving"
fi

if [ -z "$JOURNAL_SCRIPT" ]; then
    JOURNAL_SCRIPT="$JBOSS_HOME/bin/checkJournal.sh"
fi

if [ -z "$BACKUP_DIRECTORY" ]; then
    BACKUP_DIRECTORY="$JBOSS_MESSAGING_DATA_DIRECTORY/backup"
fi

if [ -z "$BINDING_DIRECTORY" ]; then
    BINDING_DIRECTORY="$JBOSS_MESSAGING_DATA_DIRECTORY/bindings/"
fi

if [ -z "$JOURNAL_DIRECTORY" ]; then
    JOURNAL_DIRECTORY="$JBOSS_MESSAGING_DATA_DIRECTORY/journal/"
fi

if [ -z "$JOURNAL_FILES" ]; then
    JOURNAL_FILES="$JOURNAL_DIRECTORY/*"
fi

if [ -z "$HORNETQ_JOURNALS_DIRECTORY" ]; then
    HORNETQ_JOURNALS_DIRECTORY="/ericsson/enm/dumps/hornetq_journals"
fi

moveJournals()
{
	error "HornetQ server's journal may be corrupt"
    if [ ! -d "$BACKUP_DIRECTORY" ]; then
        $_MKDIR "$BACKUP_DIRECTORY"
    fi
    $_MV $JOURNAL_FILES "$BACKUP_DIRECTORY"
    info "Corrupted journals has been moved to : $BACKUP_DIRECTORY"
    $_TAR "$JOURNAL_TAR" "$BACKUP_DIRECTORY" >> /dev/null  2>&1
    info "Corrupted journals has been packaged to move"
    $_RM $JOURNAL_FILES >> /dev/null  2>&1
    if [ ! -d "$HORNETQ_JOURNALS_DIRECTORY" ]; then
        $_MKDIR "$HORNETQ_JOURNALS_DIRECTORY"
    fi
    $_MV "$JOURNAL_TAR" "$HORNETQ_JOURNALS_DIRECTORY" >> /dev/null  2>&1
    if [ $? -eq 0 ] ; then
            info "Compressed corrupted journals has been moved to $HORNETQ_JOURNALS_DIRECTORY"
        $_RM "$BACKUP_DIRECTORY"
            info "Removing backup directory: $BACKUP_DIRECTORY"
    else
            info "Moving compressed corrupted journals has been failed"
    fi
}
if [ "$1" == "move_without_validation" ]
then
	info "Moving journals without validating them"
	moveJournals
else
	su jboss_user $JOURNAL_SCRIPT "$BINDING_DIRECTORY" "$JOURNAL_DIRECTORY"  >> /dev/null 2>&1 
	if [ "$?" -ne 0 ]; then
		info "Moving journals because validation Failed"
		moveJournals
	fi
fi
$_RM "$JOURNALS_MOVING_LOCK_FILE"
info "Removing lock file: $JOURNALS_MOVING_LOCK_FILE"
