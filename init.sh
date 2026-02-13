#!/bin/bash

set -e

echo "🔧 Initializing jira-cli-helpers..."
echo ""

# Check if jira-config exists in home directory
if [ -f ~/.jira-config ]; then
    echo "✅ Configuration found: ~/.jira-config"
    echo ""
else
    echo "⚠️  Configuration not found!"
    echo ""
    echo "📋 To configure JIRA CLI helpers, run:"
    echo ""
    echo "   cp $(pwd)/jira-config.dist ~/.jira-config"
    echo "   nano ~/.jira-config"
    echo ""
    echo "Then set your JIRA credentials and project details."
    echo ""
fi

# Check if already sourced in shell config
SHELL_RC=""
if [ -f ~/.zshrc ]; then
    SHELL_RC=~/.zshrc
elif [ -f ~/.bashrc ]; then
    SHELL_RC=~/.bashrc
fi

if [ -n "$SHELL_RC" ] && grep -q "jira-helpers.sh" "$SHELL_RC" 2>/dev/null; then
    echo "✅ Already sourced in $SHELL_RC"
else
    echo "⚠️  Not sourced in shell configuration!"
    echo ""
    echo "📋 To enable JIRA CLI helpers in your shell, add to $SHELL_RC:"
    echo ""
    echo "   source $(pwd)/jira-helpers.sh"
    echo ""
fi

echo "✅ jira-cli-helpers initialization complete!"
