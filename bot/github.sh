#!/bin/bash

# Function to display usage
ORG_NAME="FOSS-Community"

# Variables to store detailed information
declare -A MEMBERS
declare -A RECENT_PUSHES
declare -A REPOS
declare -A ISSUES
declare -A PULL_REQUESTS
declare -A TEAMS

# Function to fetch members
fetch_members() {
    echo "Fetching members of the organization..."
    local result=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/orgs/$ORG_NAME/members")
    echo "Result: $result"
    for member in $(echo "$result" | jq -r '.[] | @base64'); do
        local login=$(echo "$member" | base64 --decode | jq -r '.login')
        local id=$(echo "$member" | base64 --decode | jq -r '.id')
        MEMBERS["$login"]="$id"
    done
    echo "Members array: ${MEMBERS[@]}"
}

# Function to fetch recent pushes (events)
fetch_recent_pushes() {
    echo "Fetching recent pushes..."
    local result=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/orgs/$ORG_NAME/events")
    echo "Result: $result"
    echo "$result" | jq -c '.[] | select(.type=="PushEvent")' | while read -r event; do
        local repo_name=$(echo "$event" | jq -r '.repo.name')
        local pusher=$(echo "$event" | jq -r '.actor.login')
        local timestamp=$(echo "$event" | jq -r '.created_at')
        local event_url=$(echo "$event" | jq -r '.url')
        RECENT_PUSHES["$repo_name"]="$pusher | $timestamp | $event_url"
    done
    echo "Recent pushes array:"
    for repo in "${!RECENT_PUSHES[@]}"; do
        echo "- $repo: ${RECENT_PUSHES[$repo]}"
    done
}

# Function to fetch repository details
fetch_repos() {
    echo "Fetching repositories..."
    local result=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/orgs/$ORG_NAME/repos?per_page=100")
    echo "Result: $result"
    echo "$result" | jq -c '.[]' | while read -r repo; do
        local name=$(echo "$repo" | jq -r '.name')
        local description=$(echo "$repo" | jq -r '.description // "No description"')
        local language=$(echo "$repo" | jq -r '.language // "No language specified"')
        REPOS["$name"]="$description | $language"
    done
    echo "Repositories array:"
    for repo in "${!REPOS[@]}"; do
        echo "- $repo: ${REPOS[$repo]}"
    done
}

# Function to fetch pull requests
fetch_pull_requests() {
    echo "Fetching pull requests..."
    local result=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/search/issues?q=org:$ORG_NAME+type:pr&per_page=100")
    echo "Result: $result"
    local count=$(echo "$result" | jq -r '.total_count')
    echo "Total pull requests found: $count"
    if [[ $count -gt 0 ]]; then
        local index=0
        while read -r pr; do
            local repo_name=$(echo "$pr" | jq -r '.repository_url | split("/")[-1]')
            local title=$(echo "$pr" | jq -r '.title')
            local state=$(echo "$pr" | jq -r '.state')
            local created_at=$(echo "$pr" | jq -r '.created_at')
            local pr_url=$(echo "$pr" | jq -r '.html_url')

            PULL_REQUESTS["$repo_name:$title"]="$state | $created_at | $pr_url"
            ((index++))
        done < <(echo "$result" | jq -c '.items[]' | head -10)
        
        #Bro needs some serious debugging :-((
        #echo "Pull requests array:"
        #for pr_key in "${!PULL_REQUESTS[@]}"; do
            #echo "- $pr_key: ${PULL_REQUESTS[$pr_key]}"
        #done
    else
        echo "No pull requests found."
    fi
}

# Function to fetch teams
fetch_teams() {
    echo "Fetching teams..."
    local result=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/orgs/$ORG_NAME/teams?per_page=100")
    echo "Result: $result"
    echo "$result" | jq -c '.[]' | while read -r team; do
        local name=$(echo "$team" | jq -r '.name')
        local description=$(echo "$team" | jq -r '.description // "No description"')
        local members_count=$(echo "$team" | jq -r '.members_count')
        TEAMS["$name"]="$description | $members_count members"
    done
    echo "Teams array:"
    for team in "${!TEAMS[@]}"; do
        echo "- $team: ${TEAMS[$team]}"
    done
}

send_fetch_message() {
    local message="$1"
    tg --replymsg "$RET_CHAT_ID" "$RET_MSG_ID" "Fetching latest info... Keep Patience"
}


# Function to send formatted Telegram messages
send_telegram_message() {
    local message="$1"
    tg --editmarkdownv2msg "$RET_CHAT_ID" "$SENT_MSG_ID" "$message"
}

# Function to format and send member details
# Function to format and send member details
send_members() {
    send_fetch_message
    fetch_members
    local message="*Members:*"
    for login in "${!MEMBERS[@]}"; do
        local member_id="${MEMBERS[$login]}"
        # Escape characters such as ( and ) with a preceding '\'
        local escaped_login=$(echo "$login" | sed 's/[][`~!@#$%^&*()-_=+{}\|;:",<.>/?'"'"']/\\&/g')
        message+="
\\- [$escaped_login](https://github.com/$escaped_login)"
    done
    echo "$message"
    send_telegram_message "$message"
}


# Function to format and send recent pushes
send_recent_pushes() {
    fetch_recent_pushes
    local message="*Recent Pushes:*\n"
    for repo in "${!RECENT_PUSHES[@]}"; do
        local details="${RECENT_PUSHES[$repo]}"
        local pusher=$(echo "$details" | cut -d '|' -f 1 | sed 's/[][`~!@#$%^&*()-_=+{}\\|;:",<.>/?'"'"']/\\&/g')
        local timestamp=$(echo "$details" | cut -d '|' -f 2)
        local event_url=$(echo "$details" | cut -d '|' -f 3)
        message+="-$repo: Pusher - $pusher, Timestamp - $timestamp, [Event]($event_url)\n"
    done
    echo "Sending recent pushes message: $message"
    send_telegram_message "$message"
}

# Function to format and send repository details
send_repos() {
    fetch_repos
    local message="*Repositories:*\n"
    for repo in "${!REPOS[@]}"; do
        local details="${REPOS[$repo]}"
        local description=$(echo "$details" | cut -d '|' -f 1 | sed 's/[][`~!@#$%^&*()-_=+{}\\|;:",<.>/?'"'"']/\\&/g')
        local language=$(echo "$details" | cut -d '|' -f 2)
        message+="-$repo: $description, Language: $language\n"
    done
    echo "Sending repositories message: $message"
    send_telegram_message "$message"
}

# Function to format and send recent pushes
send_recent_pushes() {
    fetch_recent_pushes
    local message="*Recent Pushes:*\n"
    for repo in "${!RECENT_PUSHES[@]}"; do
        local details="${RECENT_PUSHES[$repo]}"
        local pusher=$(echo "$details" | cut -d '|' -f 1 | sed 's/[][`~!@#$%^&*()-_=+{}\\|;:",<.>/?'"'"']/\\&/g')
        local timestamp=$(echo "$details" | cut -d '|' -f 2)
        local event_url=$(echo "$details" | cut -d '|' -f 3)
        message+="- $repo: Pusher - $pusher, Timestamp - $timestamp, [Event]($event_url)\n"
    done
    echo "$message"
    send_telegram_message "$message"
}

# Function to format and send pull requests
send_pull_requests() {
    fetch_pull_requests
    local message="*Pull Requests:*"
    for pr in "${!PULL_REQUESTS[@]}"; do
        local details="${PULL_REQUESTS[$pr]}"
        local repo_name=$(echo "$pr" | cut -d ':' -f 1 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local pr_title=$(echo "$pr" | cut -d ':' -f 2 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local state=$(echo "$details" | cut -d '|' -f 1 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local created_at=$(echo "$details" | cut -d '|' -f 2 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local pr_url=$(echo "$details" | cut -d '|' -f 3 | sed 's/^ //g')
        message+="

\\- FOSS\-Community\/**${repo_name}**
[${pr_title}]($pr_url): State \\- ${state}, Created at \\- __${created_at}__"
    done
    echo "$message"
    send_telegram_message "$message"
}



# Function to format and send team details
send_teams() {
    fetch_teams
    local message="*Teams:*\n"
    for team in "${!TEAMS[@]}"; do
        local details="${TEAMS[$team]}"
        local description=$(echo "$details" | cut -d '|' -f 1 | sed 's/[][`~!@#$%^&*()-_=+{}\\|;:",<.>/?'"'"']/\\&/g')
        local members_count=$(echo "$details" | cut -d '|' -f 2)
        message+="-$team: Description - $description, Members count - $members_count\n"
    done
    echo "Sending teams message: $message"
    send_telegram_message "$message"
}

# Function to fetch open pull requests with author name
fetch_open_pull_requests() {
    echo "Fetching open pull requests..."
    local result=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/search/issues?q=org:$ORG_NAME+type:pr+state:open&per_page=100")
    echo "Result: $result"
    local count=$(echo "$result" | jq -r '.total_count')
    echo "Total open pull requests found: $count"
    if [[ $count -gt 0 ]]; then
        local index=0
        while read -r pr; do
            local repo_name=$(echo "$pr" | jq -r '.repository_url | split("/")[-1]')
            local title=$(echo "$pr" | jq -r '.title')
            local state=$(echo "$pr" | jq -r '.state')
            local created_at=$(echo "$pr" | jq -r '.created_at')
            local pr_url=$(echo "$pr" | jq -r '.html_url')
            local author=$(echo "$pr" | jq -r '.user.login')

            PULL_REQUESTS["$repo_name:$title"]="$state | $created_at | $pr_url | $author"
            ((index++))
        done < <(echo "$result" | jq -c '.items[]' | head -10)
    else
        echo "No open pull requests found."
    fi
    echo "Pull requests array: ${PULL_REQUESTS[@]}"
}

# Function to format and send open pull requests
send_open_pull_requests() {
    send_fetch_message
    fetch_open_pull_requests
    local message="*Open Pull Requests:*"
    for pr in "${!PULL_REQUESTS[@]}"; do
        local details="${PULL_REQUESTS[$pr]}"
        local repo_name=$(echo "$pr" | cut -d ':' -f 1 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local pr_title=$(echo "$pr" | cut -d ':' -f 2 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local state=$(echo "$details" | cut -d '|' -f 1 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local created_at=$(echo "$details" | cut -d '|' -f 2 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local pr_url=$(echo "$details" | cut -d '|' -f 3 | sed 's/^ //g')
        local author=$(echo "$details" | cut -d '|' -f 4 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        message+="

\\- *FOSS\\-Community\\/${repo_name}* 
[${pr_title}](${pr_url})
Created at \\- _${created_at}_
Author \\- *${author}*"
    done
    echo "$message"
    send_telegram_message "$message"
}


# Function to fetch open issues with author name
fetch_open_issues() {
    echo "Fetching open issues..."
    local result=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/search/issues?q=org:$ORG_NAME+type:issue+state:open&per_page=100")
    echo "Result: $result"
    local count=$(echo "$result" | jq -r '.total_count')
    echo "Total open issues found: $count"
    if [[ $count -gt 0 ]]; then
        local index=0
        while read -r issue; do
            local repo_name=$(echo "$issue" | jq -r '.repository_url | split("/")[-1]')
            local title=$(echo "$issue" | jq -r '.title')
            local state=$(echo "$issue" | jq -r '.state')
            local created_at=$(echo "$issue" | jq -r '.created_at')
            local issue_url=$(echo "$issue" | jq -r '.html_url')
            local author=$(echo "$issue" | jq -r '.user.login')

            ISSUES["$repo_name:$title"]="$state | $created_at | $issue_url | $author"
            ((index++))
        done < <(echo "$result" | jq -c '.items[]' | head -10)
    else
        echo "No open issues found."
    fi
    echo "Issues array: ${ISSUES[@]}"
}

# Function to format and send open issues
send_open_issues() {
    send_fetch_message
    fetch_open_issues
    local message="*Open Issues:*"
    for issue in "${!ISSUES[@]}"; do
        local details="${ISSUES[$issue]}"
        local repo_name=$(echo "$issue" | cut -d ':' -f 1 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local issue_title=$(echo "$issue" | cut -d ':' -f 2 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local state=$(echo "$details" | cut -d '|' -f 1 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local created_at=$(echo "$details" | cut -d '|' -f 2 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        local issue_url=$(echo "$details" | cut -d '|' -f 3 | sed 's/^ //g')
        local author=$(echo "$details" | cut -d '|' -f 4 | sed 's/[][`~!@#$%^&*()_=+{}\\|;:",<.>?/-]/\\&/g')
        message+="

\\- *FOSS\\-Community\\/${repo_name}*: 
[${issue_title}](${issue_url})
Created at \\- _${created_at}_
Author \\- *${author}*"
    done
    echo "$message"
    send_telegram_message "$message"
}

