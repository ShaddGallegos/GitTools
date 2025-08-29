#!/bin/bash

# Clone All Repositories for a GitHub User Script
# Bulk cloning tool for downloading all public repositories for a GitHub user/organization
#
# Features:
# - Clone all public repositories for a specified GitHub user
# - Support for GitHub.com and GitHub Enterprise
# - Progress tracking and error handling
# - Automatic directory organization
# - Resume support (skips already cloned repos)
#
# Usage:
#   ./clone_all_repos.sh USERNAME [TARGET_DIR]
#   ./clone_all_repos.sh --help
#
# Requirements:
# - curl (for GitHub API calls)
# - git (for repository operations)
# - jq (for JSON parsing) - optional but recommended
#
# Author: GitHub Repository Bulk Clone Tool
# Date: August 29, 2025

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_TARGET_DIR="$HOME/Downloads/GIT"
DEFAULT_GITHUB_URL="github.com"
DEFAULT_API_URL="https://api.github.com"

# Helper functions
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_header() { echo -e "${CYAN}========================================${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}========================================${NC}"; }

# Show help
show_help() {
  echo "Clone All Repositories for a GitHub User"
  echo ""
  echo "Usage:"
  echo "  $0 USERNAME [TARGET_DIR]"
  echo "  $0 --help"
  echo ""
  echo "Parameters:"
  echo "  USERNAME       GitHub username or organization name"
  echo "  TARGET_DIR     Target directory (default: $DEFAULT_TARGET_DIR)"
  echo ""
  echo "Examples:"
  echo "  $0 octocat"
  echo "  $0 microsoft ~/my_repos"
  echo "  $0 shaddgallegos /home/user/projects"
  echo ""
  echo "Environment Variables:"
  echo "  GITHUB_TOKEN   GitHub token for increased API rate limits (optional)"
  echo "  GITHUB_API     Custom GitHub API URL for Enterprise (optional)"
  echo ""
  echo "Features:"
  echo "  - Clones all public repositories for the specified user"
  echo "  - Skips repositories that already exist locally"
  echo "  - Shows progress and statistics"
  echo "  - Handles API rate limiting gracefully"
}

# Function to check if jq is available
check_jq() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  else
    print_warning "jq not found - falling back to basic JSON parsing"
    print_status "For better performance, install jq: sudo apt install jq"
    return 1
  fi
}

# Function to parse JSON without jq (basic fallback)
parse_clone_urls_basic() {
  local json_response="$1"
  grep -oP '"clone_url":\s*"\K[^"]*' <<< "$json_response"
}

# Function to parse JSON with jq (preferred)
parse_clone_urls_jq() {
  local json_response="$1"
  jq -r '.[].clone_url' <<< "$json_response"
}

# Function to get repository count
get_repo_count() {
  local json_response="$1"
  if check_jq; then
    jq 'length' <<< "$json_response"
  else
    grep -c '"clone_url"' <<< "$json_response"
  fi
}

# Function to clone all repositories for a user
clone_user_repos() {
  local github_user="$1"
  local target_dir="$2"
  local github_api="${GITHUB_API:-$DEFAULT_API_URL}"
  local github_token="${GITHUB_TOKEN:-}"
  
  print_header "GitHub Repository Bulk Clone"
  print_status "Target user/organization: $github_user"
  print_status "Target directory: $target_dir"
  print_status "GitHub API: $github_api"
  
  if [[ -n "$github_token" ]]; then
    print_status "Using GitHub token for authentication (increased rate limits)"
  else
    print_status "No GitHub token provided (using public API limits)"
    print_warning "Set GITHUB_TOKEN environment variable for higher rate limits"
  fi
  
  # Create target directory if it doesn't exist
  if [[ ! -d "$target_dir" ]]; then
    print_status "Creating target directory: $target_dir"
    mkdir -p "$target_dir"
  fi
  
  # Navigate to target directory
  cd "$target_dir"
  
  print_status "Fetching repository list from GitHub API..."
  
  # Build API request
  local api_url="$github_api/users/$github_user/repos?per_page=100"
  local curl_headers=()
  
  if [[ -n "$github_token" ]]; then
    curl_headers+=("-H" "Authorization: token $github_token")
  fi
  
  # Fetch repositories (handle pagination)
  local all_repos=""
  local page=1
  local max_pages=10  # Safety limit
  
  while [[ $page -le $max_pages ]]; do
    print_status "Fetching page $page..."
    
    local response
    if ! response=$(curl -s "${curl_headers[@]}" "$api_url&page=$page"); then
      print_error "Failed to fetch repository list from GitHub API"
      exit 1
    fi
    
    # Check if response is empty or contains error
    if [[ -z "$response" ]] || [[ "$response" == "[]" ]]; then
      print_status "No more repositories found (end of pagination)"
      break
    fi
    
    # Check for API errors
    if grep -q '"message"' <<< "$response"; then
      print_error "GitHub API error:"
      echo "$response" | grep '"message"' || echo "$response"
      exit 1
    fi
    
    # Append to all repos
    if [[ -z "$all_repos" ]]; then
      all_repos="$response"
    else
      # Merge JSON arrays (simple concatenation approach)
      all_repos=$(echo "$all_repos" | sed 's/]$//' && echo "$response" | sed 's/^\[/,/')
    fi
    
    # Check if we got a full page (100 repos), if not we're done
    local page_count
    if check_jq; then
      page_count=$(jq 'length' <<< "$response")
    else
      page_count=$(grep -c '"clone_url"' <<< "$response")
    fi
    
    if [[ $page_count -lt 100 ]]; then
      print_status "Last page reached (only $page_count repositories on this page)"
      break
    fi
    
    ((page++))
  done
  
  # Get repository URLs and count
  local repo_urls
  local total_repos
  
  if check_jq; then
    repo_urls=$(parse_clone_urls_jq "$all_repos")
    total_repos=$(get_repo_count "$all_repos")
  else
    repo_urls=$(parse_clone_urls_basic "$all_repos")
    total_repos=$(get_repo_count "$all_repos")
  fi
  
  if [[ -z "$repo_urls" ]]; then
    print_error "No repositories found for user: $github_user"
    print_status "This could mean:"
    print_status "  - User doesn't exist"
    print_status "  - User has no public repositories"
    print_status "  - API rate limit exceeded"
    exit 1
  fi
  
  print_success "Found $total_repos repositories for user: $github_user"
  echo ""
  
  # Clone repositories
  local cloned_count=0
  local skipped_count=0
  local failed_count=0
  local current=0
  
  while IFS= read -r repo_url; do
    [[ -z "$repo_url" ]] && continue
    
    ((current++))
    local repo_name
    repo_name=$(basename "$repo_url" .git)
    
    echo "[$current/$total_repos] Processing: $repo_name"
    
    if [[ -d "$repo_name" ]]; then
      print_warning "  Repository already exists, skipping: $repo_name"
      ((skipped_count++))
    else
      print_status "  Cloning: $repo_url"
      
      if git clone "$repo_url" 2>/dev/null; then
        print_success "  ✓ Successfully cloned: $repo_name"
        ((cloned_count++))
      else
        print_error "  ✗ Failed to clone: $repo_name"
        ((failed_count++))
      fi
    fi
    
    echo ""
  done <<< "$repo_urls"
  
  # Summary
  print_header "CLONE SUMMARY"
  echo "Total repositories found: $total_repos"
  echo "Successfully cloned: $cloned_count"
  echo "Already existed (skipped): $skipped_count"
  echo "Failed to clone: $failed_count"
  echo ""
  
  if [[ $failed_count -eq 0 ]]; then
    print_success "All operations completed successfully!"
  else
    print_warning "Some repositories failed to clone. Check the output above for details."
  fi
  
  print_status "All repositories are saved in: $target_dir"
}

# Main script logic
main() {
  case "${1:-}" in
    -h|--help)
      show_help
      exit 0
      ;;
    "")
      print_error "GitHub username is required"
      echo ""
      show_help
      exit 1
      ;;
    *)
      local github_user="$1"
      local target_dir="${2:-$DEFAULT_TARGET_DIR}"
      
      # Validate username
      if [[ ! "$github_user" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-])*[a-zA-Z0-9]$ ]] && [[ ! "$github_user" =~ ^[a-zA-Z0-9]$ ]]; then
        print_error "Invalid GitHub username format: $github_user"
        exit 1
      fi
      
      # Expand tilde in target directory
      target_dir="${target_dir/#\~/$HOME}"
      
      clone_user_repos "$github_user" "$target_dir"
      ;;
  esac
}

# Run main function with all arguments
main "$@"
