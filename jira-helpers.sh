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

jira-init() {
    local config_name="${1:-}"
    local target_config="${JIRA_CONFIG_FILE}"
    
    # If config name provided, use named config
    if [ -n "$config_name" ]; then
        target_config="$HOME/.jira-config-$config_name"
    fi
    
    echo "=== Jira CLI Configuration ==="
    echo ""
    
    # Check if config already exists and show current configuration
    if [ -f "$target_config" ]; then
        echo "⚠ Configuration already exists at: $target_config"
        echo ""
        echo "Current configuration:"
        echo "  Project: ${JIRA_PROJECT:-<not set>}"
        echo "  User: ${JIRA_USER:-<not set>}"
        echo "  URL: ${JIRA_URL:-<not set>}"
        echo ""
        echo "Options:"
        echo "  1) Overwrite this configuration"
        echo "  2) Create new named configuration (e.g., jira-init project2)"
        echo "  3) Cancel"
        echo ""
        echo -n "Choose option (1/2/3): "
        read -r choice
        
        case "$choice" in
            1)
                echo "Overwriting existing configuration..."
                ;;
            2)
                echo -n "Enter configuration name: "
                read -r new_name
                if [ -z "$new_name" ]; then
                    echo "✗ Configuration name cannot be empty"
                    return 1
                fi
                target_config="$HOME/.jira-config-$new_name"
                if [ -f "$target_config" ]; then
                    echo "✗ Configuration '$new_name' already exists"
                    return 1
                fi
                ;;
            3|*)
                echo "✗ Initialization cancelled"
                return 1
                ;;
        esac
        echo ""
    fi
    
    # Gather configuration
    echo -n "Jira URL (e.g., https://jira.adeo.com): "
    read -r jira_url
    
    echo -n "Jira Username/Email: "
    read -r jira_user
    
    echo -n "Jira API Token: "
    read -rs jira_token
    echo ""
    
    echo -n "Default Project Key (e.g., DEV1): "
    read -r jira_project
    
    echo -n "Your Jira User ID: "
    read -r jira_user_id
    
    echo -n "Board ID (optional, press Enter to skip): "
    read -r jira_board_id
    
    echo -n "Story Points Field (default: customfield_10040): "
    read -r jira_story_points
    jira_story_points="${jira_story_points:-customfield_10040}"
    
    # Validate required fields
    if [ -z "$jira_url" ] || [ -z "$jira_user" ] || [ -z "$jira_token" ] || [ -z "$jira_project" ] || [ -z "$jira_user_id" ]; then
        echo "✗ Error: All required fields must be filled"
        return 1
    fi
    
    # Create config file
    cat > "$target_config" << EOF
JIRA_URL="$jira_url"
JIRA_USER="$jira_user"
JIRA_TOKEN="$jira_token"
JIRA_PROJECT="$jira_project"
JIRA_USER_ID="$jira_user_id"
JIRA_BOARD_ID="$jira_board_id"
JIRA_STORY_POINTS_FIELD="$jira_story_points"
EOF
    
    chmod 600 "$target_config"
    
    echo ""
    echo "✓ Configuration saved to: $target_config"
    echo "✓ File permissions set to 600 (owner read/write only)"
    echo ""
    
    # Show how to switch contexts if named config
    if [ "$target_config" != "$JIRA_CONFIG_FILE" ]; then
        local config_name=$(basename "$target_config" | sed 's/^\.jira-config-//')
        echo "To use this configuration, run:"
        echo "  export JIRA_CONFIG_FILE=\"$target_config\""
        echo "  source jira-helpers.sh"
        echo ""
        echo "Or create an alias in your shell config:"
        echo "  alias jira-$config_name='JIRA_CONFIG_FILE=\"$target_config\" source jira-helpers.sh'"
        echo ""
        return 0
    fi
    
    # Add to shell configuration
    echo -n "Add jira-helpers to shell startup? (y/n): "
    read -r add_to_shell
    
    if [[ "$add_to_shell" =~ ^[Yy]$ ]]; then
        local shell_config=""
        local current_shell=$(basename "$SHELL")
        
        case "$current_shell" in
            zsh)
                shell_config="$HOME/.zshrc"
                ;;
            bash)
                if [ -f "$HOME/.bash_profile" ]; then
                    shell_config="$HOME/.bash_profile"
                else
                    shell_config="$HOME/.bashrc"
                fi
                ;;
            *)
                echo "⚠ Unsupported shell: $current_shell"
                echo "Add this line manually to your shell config:"
                echo "  source $(realpath "${BASH_SOURCE[0]:-$0}")"
                return 0
                ;;
        esac
        
        # Get the absolute path to jira-helpers.sh
        local script_path="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/$(basename "${BASH_SOURCE[0]:-$0}")"
        local source_line="source \"$script_path\""
        
        # Check if already added
        if grep -qF "$source_line" "$shell_config" 2>/dev/null; then
            echo "✓ Already added to $shell_config"
        else
            echo "" >> "$shell_config"
            echo "# Jira CLI Helpers" >> "$shell_config"
            echo "$source_line" >> "$shell_config"
            echo "✓ Added to $shell_config"
        fi
        
        echo ""
        echo "Reload your shell with: exec $SHELL"
    fi
}

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

jira-task() {
    local summary="$1"
    local description="${2:-}"
    
    # Interactive mode if no summary provided
    if [ -z "$summary" ]; then
        echo "=== Quick Task Creation ==="
        echo -n "Task title: "
        read -r summary
        
        if [ -z "$summary" ]; then
            echo "✗ Error: Task title cannot be empty"
            return 1
        fi
        
        echo -n "Task description (optional, press Enter to skip): "
        read -r description
    fi
    
    # Validate summary length
    if [ ${#summary} -lt 3 ]; then
        echo "✗ Error: Task title too short (minimum 3 characters)"
        return 1
    fi
    
    # Create the task
    echo "Creating task in project $JIRA_PROJECT..."
    local result=$(curl -s -X POST \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue" \
        -d "{
            \"fields\": {
                \"project\": {\"key\": \"$JIRA_PROJECT\"},
                \"summary\": \"$summary\",
                \"description\": \"$description\",
                \"issuetype\": {\"name\": \"Task\"}
            }
        }")
    
    # Parse and display result
    local issue_key=$(echo "$result" | jq -r '.key // empty')
    
    if [ -n "$issue_key" ]; then
        echo "✓ Task created successfully: $issue_key"
        echo "  URL: $JIRA_URL/browse/$issue_key"
        echo "  Summary: $summary"
        [ -n "$description" ] && echo "  Description: $description"
        
        # Offer to assign to self
        echo -n "Assign to yourself? (y/n): "
        read -r assign_answer
        if [[ "$assign_answer" =~ ^[Yy]$ ]]; then
            if jira-assign-me "$issue_key"; then
                echo ""
            else
                echo "⚠ Warning: Failed to assign task to yourself"
            fi
        fi
    else
        local error_msg=$(echo "$result" | jq -r '.errorMessages // .errors | tostring')
        echo "✗ Error creating task: $error_msg"
        return 1
    fi
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
    local task_status="${1:-In Progress,To Do,New}"
    
    echo "=== My Tasks ($task_status) ==="
    curl -s -X GET \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/search?jql=assignee=currentUser()+AND+status+in+($task_status)+ORDER+BY+created+DESC&maxResults=50" \
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

jira-change-type() {
    local issue_key="$1"
    local new_type="$2"
    
    if [ -z "$issue_key" ] || [ -z "$new_type" ]; then
        echo "Usage: jira-change-type DEV1-123 Task"
        echo "Types: Task, Bug, Story, Sub-task"
        return 1
    fi
    
    curl -s -X PUT \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$issue_key" \
        -d "{\"fields\": {\"issuetype\": {\"name\": \"$new_type\"}}}" \
        && echo "✓ Changed $issue_key type to $new_type" \
        || echo "✗ Failed to change type"
}

jira-transition() {
    local issue_key="$1"
    local target_status="$2"
    
    if [ -z "$issue_key" ] || [ -z "$target_status" ]; then
        echo "Usage: jira-transition DEV1-123 Done"
        echo "Common statuses: Done, In Progress, To Do"
        return 1
    fi
    
    # Get available transitions
    local transitions=$(curl -s -X GET \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$issue_key/transitions")
    
    # Find transition ID by name
    local transition_id=$(echo "$transitions" | jq -r ".transitions[] | select(.name | ascii_downcase | contains(\"$(echo $target_status | tr '[:upper:]' '[:lower:]')\")) | .id" | head -1)
    
    if [ -z "$transition_id" ]; then
        echo "✗ Could not find transition to '$target_status'"
        echo "Available transitions:"
        echo "$transitions" | jq -r '.transitions[] | "  - \(.name)"'
        return 1
    fi
    
    curl -s -X POST \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$issue_key/transitions" \
        -d "{\"transition\": {\"id\": \"$transition_id\"}}" \
        && echo "✓ Transitioned $issue_key to $target_status" \
        || echo "✗ Failed to transition"
}

jira-transition-to() {
    local issue_key="$1"
    local target_status="$2"
    local max_hops="${3:-10}"
    
    if [ -z "$issue_key" ] || [ -z "$target_status" ]; then
        echo "Usage: jira-transition-to DEV1-123 \"Done\" [max_hops]"
        echo "Automatically transitions through intermediate statuses to reach target"
        return 1
    fi
    
    local current_hop=0
    local visited_statuses=()
    
    # Preferred transition patterns (order matters)
    local forward_keywords=("review" "test" "build" "progress" "approve" "gotowe" "done" "close")
    local avoid_keywords=("block" "reject" "cancel" "reopen")
    
    while [ $current_hop -lt $max_hops ]; do
        # Get current status and available transitions
        local issue_data=$(curl -s -X GET \
            -H "Authorization: Bearer $JIRA_TOKEN" \
            -H "Content-Type: application/json" \
            "$JIRA_URL/rest/api/2/issue/$issue_key?fields=status")
        
        local current_status=$(echo "$issue_data" | jq -r '.fields.status.name')
        
        # Check if we reached target
        if [ "$(echo "$current_status" | tr '[:upper:]' '[:lower:]')" = "$(echo "$target_status" | tr '[:upper:]' '[:lower:]')" ]; then
            echo "✓ Successfully transitioned $issue_key to $target_status"
            return 0
        fi
        
        # Prevent infinite loops
        if [[ " ${visited_statuses[@]} " =~ " ${current_status} " ]]; then
            echo "✗ Loop detected at status '$current_status'"
            return 1
        fi
        visited_statuses+=("$current_status")
        
        echo "→ Current status: $current_status (hop $((current_hop + 1))/$max_hops)"
        
        # Get available transitions
        local transitions=$(curl -s -X GET \
            -H "Authorization: Bearer $JIRA_TOKEN" \
            -H "Content-Type: application/json" \
            "$JIRA_URL/rest/api/2/issue/$issue_key/transitions")
        
        # Try direct transition to target
        local transition_id=$(echo "$transitions" | jq -r ".transitions[] | select(.name | ascii_downcase | contains(\"$(echo $target_status | tr '[:upper:]' '[:lower:]')\")) | .id" | head -1)
        local transition_name=""
        
        if [ -z "$transition_id" ]; then
            # No direct path - use smart selection
            # 1. First, filter out blocked/rejected transitions
            local filtered_transitions=$(echo "$transitions" | jq -c '[.transitions[] | select(.name | ascii_downcase | (contains("block") or contains("reject") or contains("cancel") or contains("reopen")) | not)]')
            
            # 2. Try to find forward-moving transition
            for keyword in "${forward_keywords[@]}"; do
                transition_id=$(echo "$filtered_transitions" | jq -r ".[] | select(.name | ascii_downcase | contains(\"$keyword\")) | .id" | head -1)
                if [ -n "$transition_id" ]; then
                    transition_name=$(echo "$filtered_transitions" | jq -r ".[] | select(.id == \"$transition_id\") | .name")
                    break
                fi
            done
            
            # 3. If still no transition, take first filtered one
            if [ -z "$transition_id" ]; then
                transition_id=$(echo "$filtered_transitions" | jq -r '.[0].id')
                transition_name=$(echo "$filtered_transitions" | jq -r '.[0].name')
            fi
            
            # 4. Last resort - take any transition
            if [ -z "$transition_id" ] || [ "$transition_id" = "null" ]; then
                transition_id=$(echo "$transitions" | jq -r '.transitions[0].id')
                transition_name=$(echo "$transitions" | jq -r '.transitions[0].name')
            fi
            
            if [ -z "$transition_id" ] || [ "$transition_id" = "null" ]; then
                echo "✗ No available transitions from '$current_status'"
                echo "Available transitions:"
                echo "$transitions" | jq -r '.transitions[] | "  - \(.name)"'
                return 1
            fi
            
            echo "  ↳ No direct path, trying: $transition_name"
        else
            transition_name=$(echo "$transitions" | jq -r ".transitions[] | select(.id == \"$transition_id\") | .name")
            echo "  ↳ Direct path found to: $target_status"
        fi
        
        # Execute transition
        local result=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Authorization: Bearer $JIRA_TOKEN" \
            -H "Content-Type: application/json" \
            "$JIRA_URL/rest/api/2/issue/$issue_key/transitions" \
            -d "{\"transition\": {\"id\": \"$transition_id\"}}")
        
        local http_code=$(echo "$result" | tail -n1)
        
        if [ "$http_code" != "204" ]; then
            echo "✗ Transition failed (HTTP $http_code)"
            return 1
        fi
        
        current_hop=$((current_hop + 1))
        sleep 0.5  # Small delay to allow Jira to update
    done
    
    echo "✗ Could not reach '$target_status' within $max_hops transitions"
    return 1
}

jira-mark-done() {
    local issue_key="$1"
    
    if [ -z "$issue_key" ]; then
        echo "Usage: jira-mark-done DEV1-123"
        return 1
    fi
    
    # Try both English and Polish names for Done status
    jira-transition-to "$issue_key" "Gotowe" 10 || jira-transition-to "$issue_key" "Done" 10
}

jira-ctx() {
    local config_name="$1"
    
    if [ -z "$config_name" ]; then
        echo "=== Available Jira Configurations ==="
        echo ""
        
        # Build array of available configs
        local -a config_list
        local -a config_paths
        local -a config_projects
        local -a config_users
        local idx=1
        
        # Add default config
        if [ -f "$HOME/.jira-config" ]; then
            source "$HOME/.jira-config"
            config_list+=("default")
            config_paths+=("$HOME/.jira-config")
            config_projects+=("${JIRA_PROJECT}")
            config_users+=("${JIRA_USER}")
        fi
        
        # Add named configs
        setopt localoptions nullglob 2>/dev/null || shopt -s nullglob 2>/dev/null
        local configs=("$HOME"/.jira-config-*)
        for config in "${configs[@]}"; do
            if [ -f "$config" ]; then
                local name=$(basename "$config" | sed 's/^\.jira-config-//')
                source "$config"
                config_list+=("$name")
                config_paths+=("$config")
                config_projects+=("${JIRA_PROJECT}")
                config_users+=("${JIRA_USER}")
            fi
        done
        
        # Display numbered list
        if [ ${#config_list[@]} -eq 0 ]; then
            echo "No configurations found. Run 'jira-init' to create one."
            return 1
        fi
        
        for ((i=1; i<=${#config_list[@]}; i++)); do
            local current_marker=""
            if [ "${config_paths[$i]}" = "${JIRA_CONFIG_FILE}" ]; then
                current_marker=" (current)"
            fi
            echo "  [$i] ${config_list[$i]}$current_marker"
            echo "      Project: ${config_projects[$i]}"
            echo "      User: ${config_users[$i]}"
            echo ""
        done
        
        echo -n "Select configuration (1-${#config_list[@]}) or press Enter to cancel: "
        read -r selection
        
        if [ -z "$selection" ]; then
            echo "Cancelled"
            return 0
        fi
        
        if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#config_list[@]} ]; then
            echo "✗ Invalid selection"
            return 1
        fi
        
        config_name="${config_list[$selection]}"
    fi
    
    # Switch to selected config
    local target_config=""
    if [ "$config_name" = "default" ]; then
        target_config="$HOME/.jira-config"
    else
        target_config="$HOME/.jira-config-$config_name"
    fi
    
    if [ ! -f "$target_config" ]; then
        echo "✗ Configuration '$config_name' not found at: $target_config"
        echo "Run 'jira-ctx' to see available configurations"
        return 1
    fi
    
    export JIRA_CONFIG_FILE="$target_config"
    source "$target_config"
    
    echo "✓ Switched to configuration: $config_name"
    echo "  Project: ${JIRA_PROJECT}"
    echo "  User: ${JIRA_USER}"
}

# Alias for backward compatibility
jira-switch() {
    jira-ctx "$@"
}

jira-checklist() {
    local key="$1"
    shift
    local items=("$@")
    
    if [ -z "$key" ] || [ ${#items[@]} -eq 0 ]; then
        echo "Usage: jira-checklist DEV1-123 \"Item 1\" \"Item 2\" \"Item 3\""
        return 1
    fi
    
    # Build checklist items in Jira format
    local checklist_items="["
    local first=true
    for item in "${items[@]}"; do
        if [ "$first" = false ]; then
            checklist_items+=","
        fi
        checklist_items+="{\"name\":\"$item\",\"checked\":false}"
        first=false
    done
    checklist_items+="]"
    
    # Try to find checklist custom field (usually customfield_10060 or similar)
    # Get issue to find available custom fields
    local response=$(curl -s -X GET \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$key?fields=*all")
    
    # Look for checklist field (common names: customfield_10060, customfield_10070, etc)
    local checklist_field=$(echo "$response" | jq -r '.fields | keys[] | select(startswith("customfield_10")) | select(. as $k | .fields[$k] // {} | type == "object" and has("items"))' | head -1)
    
    if [ -z "$checklist_field" ]; then
        echo "✗ Could not find checklist custom field. Adding as comment instead..."
        local comment_text="*Checklist:*"
        for item in "${items[@]}"; do
            comment_text+="\\n- [ ] $item"
        done
        jira-comment "$key" "$comment_text"
        return
    fi
    
    # Update issue with checklist
    curl -s -X PUT \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        -H "Content-Type: application/json" \
        "$JIRA_URL/rest/api/2/issue/$key" \
        -d "{\"fields\": {\"$checklist_field\": $checklist_items}}" \
        && echo "✓ Added checklist to $key" \
        || echo "✗ Failed to add checklist"
}
