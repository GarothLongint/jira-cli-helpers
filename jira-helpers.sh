#!/bin/bash

# Load configuration from external file
JIRA_CONFIG_FILE="${JIRA_CONFIG_FILE:-$HOME/.jira-config}"

if [ ! -f "$JIRA_CONFIG_FILE" ]; then
    echo "Error: Jira config file not found at $JIRA_CONFIG_FILE"
    echo "Create it with:"
    echo "  cat > ~/.jira-config << 'EOF'"
    echo "  JIRA_URL=\"https://jira.adeo.com\""
    echo "  JIRA_USER=\"your.email@example.com\""
    echo "  JIRA_TOKEN=\"your-token\""
    echo "  JIRA_PROJECT=\"DEV1\""
    echo "  JIRA_USER_ID=\"your-user-id\""
    echo "  JIRA_BOARD_ID=\"14401\""
    echo "  JIRA_STORY_POINTS_FIELD=\"customfield_10040\""
    echo "  EOF"
    return 1
fi

# Source the config file
source "$JIRA_CONFIG_FILE"

# Export variables for use in functions
export JIRA_URL
export JIRA_USER
export JIRA_TOKEN
export JIRA_PROJECT
export JIRA_USER_ID
export JIRA_BOARD_ID
export JIRA_STORY_POINTS_FIELD

jira-create() {
    local summary="$1"
    local description="${2:-}"
    local type="${3:-Task}"
    
    if [ -z "$summary" ]; then
        echo "Usage: jira-create \"Summary\" [\"Description\"] [Type]"
        echo "Types: Task, Bug, Story, Sub-task"
        return 1
    fi
    
    curl -s -X POST \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue" \
        -d "{
            \"fields\": {
                \"project\": {\"key\": \"$JIRA_PROJECT\"},
                \"summary\": \"$summary\",
                \"description\": \"$description\",
                \"issuetype\": {\"name\": \"$type\"}
            }
        }" | jq -r 'if .key then "✓ Created: \(.key) - \(.self)" else "✗ Error: \(.errorMessages // .errors | tostring)" end'
}

jira-list() {
    local limit="${1:-10}"
    curl -s -X GET \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/search?jql=project=$JIRA_PROJECT+order+by+created+DESC&maxResults=$limit" \
        | jq -r '.issues[] | "\(.key): \(.fields.summary) [\(.fields.status.name)]"'
}

jira-get() {
    local key="$1"
    if [ -z "$key" ]; then
        echo "Usage: jira-get DEV1-123"
        return 1
    fi
    
    curl -s -X GET \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$key" \
        | jq -r '"\(.key): \(.fields.summary)\nStatus: \(.fields.status.name)\nAssignee: \(.fields.assignee.displayName // "Unassigned")\nReporter: \(.fields.reporter.displayName)\nCreated: \(.fields.created)\n\nDescription:\n\(.fields.description // "No description")"'
}

jira-assign-me() {
    local key="$1"
    if [ -z "$key" ]; then
        echo "Usage: jira-assign-me DEV1-123"
        return 1
    fi
    
    curl -s -X PUT \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$key/assignee" \
        -d "{\"name\": \"$JIRA_USER_ID\"}" \
        && echo "✓ Assigned $key to you"
}

jira-comment() {
    local key="$1"
    local comment="$2"
    
    if [ -z "$key" ] || [ -z "$comment" ]; then
        echo "Usage: jira-comment DEV1-123 \"Your comment\""
        return 1
    fi
    
    curl -s -X POST \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$key/comment" \
        -d "{\"body\": \"$comment\"}" \
        | jq -r 'if .id then "✓ Comment added to \(.self)" else "✗ Error: \(.errorMessages // .errors | tostring)" end'
}

jira-search() {
    local jql="$1"
    local limit="${2:-20}"
    
    if [ -z "$jql" ]; then
        echo "Usage: jira-search \"status=Open\" [limit]"
        return 1
    fi
    
    curl -s -X GET \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/search?jql=$jql&maxResults=$limit" \
        | jq -r '.issues[] | "\(.key): \(.fields.summary) [\(.fields.status.name)]"'
}

jira-story-points() {
    local key="$1"
    local points="$2"
    
    if [ -z "$key" ] || [ -z "$points" ]; then
        echo "Usage: jira-story-points DEV1-123 5"
        return 1
    fi
    
    curl -s -X PUT \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$key" \
        -d "{\"fields\": {\"$JIRA_STORY_POINTS_FIELD\": $points}}" \
        && echo "✓ Set story points to $points for $key" \
        || echo "✗ Failed to set story points"
}

jira-my-tasks() {
    local status="${1:-In Progress,To Do,New}"
    
    echo "=== My Tasks ($status) ==="
    curl -s -X GET \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/search?jql=assignee=currentUser()+AND+status+in+($status)+ORDER+BY+created+DESC&maxResults=50" \
        | jq -r '.issues[] | "\(.key): \(.fields.summary) [\(.fields.status.name)]"'
}

jira-active-sprint() {
    echo "=== Getting Active Sprint ==="
    curl -s -X GET \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/agile/1.0/board/$JIRA_BOARD_ID/sprint?state=active" \
        | jq -r '.values[] | "Sprint ID: \(.id) - \(.name) (State: \(.state))"'
}

jira-move-to-sprint() {
    local issue_keys="$1"
    local sprint_id="$2"
    
    if [ -z "$issue_keys" ] || [ -z "$sprint_id" ]; then
        echo "Usage: jira-move-to-sprint \"DEV1-123,DEV1-124\" SPRINT_ID"
        echo "To get active sprint ID, use: jira-active-sprint"
        return 1
    fi
    
    # Convert comma-separated string to JSON array
    local issues_json=$(echo "$issue_keys" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
    
    curl -s -X POST \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/agile/1.0/sprint/$sprint_id/issue" \
        -d "{\"issues\": [$issues_json]}" \
        && echo "✓ Moved issues to sprint $sprint_id" \
        || echo "✗ Failed to move issues"
}

jira-update() {
    local key="$1"
    local description="$2"
    
    if [ -z "$key" ] || [ -z "$description" ]; then
        echo "Usage: jira-update DEV1-123 \"New description\""
        return 1
    fi
    
    curl -s -X PUT \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$key" \
        -d "{\"fields\": {\"description\": \"$description\"}}" \
        && echo "✓ Updated $key description" \
        || echo "✗ Failed to update description"
}

jira-set-epic() {
    local issue_key="$1"
    local epic_key="$2"
    
    if [ -z "$issue_key" ] || [ -z "$epic_key" ]; then
        echo "Usage: jira-set-epic DEV1-123 DEV1-456"
        return 1
    fi
    
    curl -s -X PUT \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$issue_key" \
        -d "{\"fields\": {\"customfield_10008\": \"$epic_key\"}}" \
        && echo "✓ Set epic $epic_key for $issue_key" \
        || echo "✗ Failed to set epic"
}
