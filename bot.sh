#!/bin/bash

#Clear & Clean terminal before starting
clear
rm -f bot.log

# Source core utils
source .token.sh
source util.sh

# Source functions
source bot/github.sh
source bot/log_dump.sh
source bot/reset_log.sh
source bot/round.sh
source bot/start.sh
source bot/weath.sh
source bot/bot_util.sh

log -i tgbot "STARTING BOT"


# Defining constan# Initialize update
update_init

## While loop
while true; do
    # Refresh stuff
    update
    [ "$RET_MSG_TEXT" ] && log -v tgbot "Message received: $RET_MSG_TEXT" | tee -a log
    [ "$RET_MSG_TEXT" ] && log -v tgbot " -> Chat title: $RET_CHAT_TITLE" | tee -a log &
    [ "$RET_MSG_TEXT" ] && log -v tgbot " -> Chat id: $RET_CHAT_ID" | tee -a log &
    RET_LOWERED_MSG_TEXT=$(tr '[:upper:]' '[:lower:]' <<<"$RET_MSG_TEXT")

    case $RET_LOWERED_MSG_TEXT in

    '/start'*) start | tee -a log ;;
    '/issues'*) send_open_issues ;;
    '.weath'*) weath  | tee -a log ;;
    '.log'*) log_dump ;;
    '/members'*) send_members ;;
    '/prs'*) send_open_pull_requests ;;
    '.reset_log'*) reset_log ;;
    '.restart'*) bot_util::restart ;;
    '.update'*) bot_util::update ;;
    esac

    unset RET_MSG_TEXT RET_REPLIED_MSG_ID
done


