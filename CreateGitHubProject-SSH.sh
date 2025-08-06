#!/bin/bash

# Enhanced GitHub Project Creation Script (SSH Version)
# Uses SSH authentication for better security

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=========================================="
echo "    GitHub Project Creation Tool (SSH)"
echo "=========================================="
echo ""
echo "GitHub Instance Configuration:"
echo "• For GitHub.com: Just press Enter"
echo "• For Enterprise: Enter domain only (e.g., github.company.com)"
echo ""

read -p "Enter GitHub domain (press Enter for github.com): " github_url
if [[ -z "$github_url" ]]; then
    github_url="github.com"
    api_url="https://api.github.com"
    ssh_host="git@github.com"
else
    # Remove protocol if provided
    github_url=${github_url#https://}
    github_url=${github_url#http://}
    # Remove trailing slash if present
    github_url=${github_url%/}
    
    # Extract domain from URL (remove username/org paths)
    # If user enters "github.com/username" or full profile URL, extract just "github.com"
    if [[ "$github_url" == *"github.com"* ]]; then
        github_url="github.com"
    else
        # For enterprise instances, take only the domain part
        github_url=$(echo "$github_url" | cut -d'/' -f1)
    fi
    
    # Set API URL and SSH host based on GitHub instance
    if [[ "$github_url" == "github.com" ]]; then
        api_url="https://api.github.com"
        ssh_host="git@github.com"
    else
        api_url="https://$github_url/api/v3"
        ssh_host="git@$github_url"
    fi
fi

print_status "Using GitHub instance: $github_url"
print_status "API endpoint: $api_url"
print_status "SSH host: $ssh_host"

read -p "Enter full path to your local project directory: " project_path
read -p "Enter your GitHub username: " gh_user
read -s -p "Enter your GitHub personal access token (for API only): " gh_token
echo ""

# Validate inputs
if [[ -z "$project_path" || -z "$gh_user" || -z "$gh_token" ]]; then
    print_error "All fields are required!"
    exit 1
fi

# Extract repo name from the last folder in the path
repo_name=$(basename "$project_path")
repo_url="$ssh_host:$gh_user/$repo_name.git"

# Check if SSH key is available
if ! ssh -T "$ssh_host" 2>&1 | grep -q "successfully authenticated"; then
    print_warning "SSH key not configured for $github_url."
    print_status "To set up SSH authentication:"
    print_status "1. Generate SSH key: ssh-keygen -t ed25519 -C 'your_email@example.com'"
    print_status "2. Add to SSH agent: ssh-add ~/.ssh/id_ed25519"
    print_status "3. Add public key to $github_url: https://$github_url/settings/keys"
    print_status ""
    print_status "For now, falling back to HTTPS with token..."
    repo_url="https://${gh_token}@${github_url}/$gh_user/$repo_name.git"
else
    print_success "SSH authentication available!"
fi

# Navigate to the project directory
print_status "Navigating to project directory: $project_path"
cd "$project_path" || { 
    print_error "Directory not found: $project_path"
    exit 1
}

# Initialize Git repo if not already
if [ ! -d ".git" ]; then
    print_status "Initializing Git repository..."
    git init
    git config init.defaultBranch main
else
    print_status "Git repository already exists"
fi

# Set up Git configuration if not set
if [[ -z "$(git config user.name 2>/dev/null || true)" ]]; then
    print_status "Setting up Git user configuration..."
    read -p "Enter your Git user name: " git_name
    read -p "Enter your Git email: " git_email
    git config user.name "$git_name"
    git config user.email "$git_email"
fi

# Check if there are any files to commit
if git diff --cached --exit-code >/dev/null && git diff --exit-code >/dev/null && [ -z "$(git ls-files)" ]; then
    print_warning "No files found to commit. Adding all files..."
    git add .
fi

# Check if there are uncommitted changes
if ! git diff --cached --exit-code >/dev/null; then
    print_status "Committing changes..."
    git commit -m "Initial commit - automated upload"
elif [ -n "$(git ls-files)" ] && [ -z "$(git log --oneline -1 2>/dev/null)" ]; then
    print_status "Creating initial commit..."
    git add .
    git commit -m "Initial commit - automated upload"
else
    print_status "Repository is already committed and up to date"
fi

# Create repo on GitHub using API
print_status "Creating GitHub repository: $repo_name"
response=$(curl -s -w "%{http_code}" \
    -H "Authorization: token $gh_token" \
    -H "Accept: application/vnd.github.v3+json" \
    "$api_url/user/repos" \
    -d "{\"name\":\"$repo_name\",\"private\":false,\"description\":\"Automated upload of $repo_name project\"}" \
    -o /tmp/github_response.json)

http_code="${response: -3}"

if [[ "$http_code" == "201" ]]; then
    print_success "GitHub repository created successfully!"
elif [[ "$http_code" == "422" ]]; then
    if grep -q "name already exists" /tmp/github_response.json; then
        print_warning "Repository already exists on GitHub. Continuing with push..."
    else
        print_error "Repository creation failed. Response:"
        cat /tmp/github_response.json
        exit 1
    fi
else
    print_error "Failed to create repository. HTTP Code: $http_code"
    cat /tmp/github_response.json
    exit 1
fi

# Add remote if it doesn't exist
if ! git remote get-url origin >/dev/null 2>&1; then
    print_status "Adding remote origin..."
    git remote add origin "$repo_url"
else
    print_status "Remote origin already exists, updating URL..."
    git remote set-url origin "$repo_url"
fi

# Ensure we're on main branch
current_branch=$(git branch --show-current)
if [[ "$current_branch" != "main" ]]; then
    print_status "Switching to main branch..."
    git branch -M main
fi

# Check if repository exists and handle synchronization
repo_exists=false
if [[ "$http_code" == "422" ]] && grep -q "name already exists" /tmp/github_response.json; then
    repo_exists=true
fi

if [[ "$repo_exists" == true ]]; then
    print_status "Repository exists on GitHub. Checking for differences..."
    
    # Fetch remote branches and tags
    print_status "Fetching remote information..."
    if git fetch origin 2>/dev/null; then
        print_success "Successfully fetched remote information"
        
        # Check if remote main branch exists
        if git ls-remote --heads origin main | grep -q main; then
            print_status "Remote main branch found. Analyzing differences..."
            
            # Get commit counts
            local_commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
            remote_commits=$(git rev-list --count origin/main 2>/dev/null || echo "0")
            
            # Check for divergence
            behind_count=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
            ahead_count=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
            
            print_status "Local commits: $local_commits, Remote commits: $remote_commits"
            print_status "Behind remote: $behind_count commits, Ahead of remote: $ahead_count commits"
            
            if [[ "$behind_count" -gt 0 && "$ahead_count" -gt 0 ]]; then
                print_warning "Repositories have diverged! Local and remote have different commits."
                echo "Options:"
                echo "1) Merge remote changes (recommended)"
                echo "2) Force push local changes (overwrites remote)"
                echo "3) Cancel operation"
                read -p "Choose option (1-3): " sync_option
                
                case $sync_option in
                    1)
                        print_status "Merging remote changes..."
                        if git merge origin/main --no-edit; then
                            print_success "Successfully merged remote changes"
                        else
                            print_error "Merge conflicts detected. Please resolve manually:"
                            git status
                            exit 1
                        fi
                        ;;
                    2)
                        print_warning "Force pushing will overwrite remote repository!"
                        read -p "Are you sure? (y/N): " confirm
                        if [[ "$confirm" =~ ^[Yy]$ ]]; then
                            print_status "Force pushing to GitHub..."
                            if git push -f origin main; then
                                print_success "Successfully force pushed to GitHub!"
                            else
                                print_error "Failed to force push to GitHub"
                                exit 1
                            fi
                        else
                            print_status "Operation cancelled"
                            exit 0
                        fi
                        ;;
                    3)
                        print_status "Operation cancelled"
                        exit 0
                        ;;
                    *)
                        print_error "Invalid option"
                        exit 1
                        ;;
                esac
            elif [[ "$behind_count" -gt 0 ]]; then
                print_status "Local repository is behind remote. Pulling changes..."
                if git pull origin main --no-edit; then
                    print_success "Successfully pulled remote changes"
                else
                    print_error "Failed to pull remote changes"
                    exit 1
                fi
            elif [[ "$ahead_count" -gt 0 ]]; then
                print_status "Local repository is ahead of remote. Will push changes..."
            else
                print_success "Local and remote repositories are in sync"
            fi
        else
            print_status "Remote repository is empty. Will push local content..."
        fi
    else
        print_warning "Failed to fetch remote information. Trying alternative authentication..."
        # For SSH version, if SSH fails, try HTTPS with token
        if [[ "$repo_url" == git@* ]]; then
            print_status "SSH fetch failed, trying HTTPS with token..."
            temp_url="https://${gh_token}@${github_url}/$gh_user/$repo_name.git"
            git remote set-url origin "$temp_url"
            
            if git fetch origin 2>/dev/null; then
                print_success "Successfully fetched with HTTPS authentication"
                # Analyze differences with HTTPS
                if git ls-remote --heads origin main | grep -q main; then
                    behind_count=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
                    ahead_count=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
                    
                    if [[ "$behind_count" -gt 0 ]]; then
                        print_status "Pulling remote changes..."
                        git pull origin main --no-edit
                    fi
                fi
                # Switch back to original URL for push
                git remote set-url origin "$repo_url"
            else
                print_warning "Could not fetch remote repository. Proceeding with push..."
                git remote set-url origin "$repo_url"
            fi
        else
            print_warning "Could not fetch remote repository. Proceeding with push..."
        fi
    fi
fi

# Push to GitHub
print_status "Pushing to GitHub..."
if git push -u origin main; then
    print_success "Successfully pushed to GitHub!"
else
    print_error "Failed to push to GitHub."
    if [[ "$repo_url" == git@* ]]; then
        print_error "SSH push failed. Please check your SSH key configuration."
        print_status "You can test SSH with: ssh -T $ssh_host"
    else
        print_error "HTTPS push failed. Please check your token permissions."
        print_error "Make sure your token has 'repo' scope enabled."
    fi
    exit 1
fi

# Clean up
rm -f /tmp/github_response.json

echo ""
echo "=========================================="
print_success "Project '$repo_name' has been successfully pushed to GitHub!"
echo "Repository URL: https://$github_url/$gh_user/$repo_name"
echo "SSH Clone URL: $ssh_host:$gh_user/$repo_name.git"
echo "HTTPS Clone URL: https://$github_url/$gh_user/$repo_name.git"
echo "=========================================="

# Optional: Open the repository in browser
read -p "Do you want to open the repository in your browser? (y/N): " open_browser
if [[ "$open_browser" =~ ^[Yy]$ ]]; then
    if command -v xdg-open >/dev/null; then
        xdg-open "https://$github_url/$gh_user/$repo_name"
    elif command -v firefox >/dev/null; then
        firefox "https://$github_url/$gh_user/$repo_name" &
    else
        print_status "Please manually open: https://$github_url/$gh_user/$repo_name"
    fi
fi
