# Git Tools

**Created:** June 2024

## Synopsis

A collection of Git automation tools and scripts for managing GitHub repositories, including bulk repository cloning, project creation, and repository management utilities. Provides both SSH and HTTPS support for GitHub operations.

## Supported Operating Systems

- Linux (All distributions with Git and curl/wget)
- macOS (with Git and Xcode command line tools)
- Windows (with Git Bash or WSL)

## Quick Usage

### Basic Repository Creation

```bash
# Create a new GitHub project with HTTPS
./CreateGitHubProject.sh

# Create a new GitHub project with SSH
./CreateGitHubProject-SSH.sh
```

### Bulk Repository Operations

```bash
# Navigate to the Clone_All_Repos_for_a_GitHub directory
cd Clone_All_Repos_for_a_GitHub

# Run the bulk cloning tool
./clone_all_repos.sh username
```

### Interactive Project Creation

The scripts provide interactive prompts for:

1. Repository name specification
2. Description input
3. Visibility settings (public/private)
4. Initial commit configuration
5. Remote origin setup
6. SSH key configuration (SSH version)

## Features and Capabilities

### Core Features

- Automated GitHub repository creation
- Bulk repository cloning from GitHub accounts
- SSH and HTTPS authentication support
- Interactive project setup wizards
- Automated initial commit and push operations

### Repository Management

- Multi-repository cloning operations
- Repository visibility configuration
- Remote origin management
- Branch initialization and setup
- Git configuration automation

### Authentication Methods

- GitHub Personal Access Token support
- SSH key authentication
- HTTPS credential management
- Automated credential validation
- Secure credential storage guidance

### Automation Features

- Batch processing capabilities
- Error handling and validation
- Progress monitoring
- Automated directory structure creation
- Git configuration verification

## Limitations

- Requires valid GitHub account and authentication
- Network connectivity required for all GitHub operations
- Rate limiting may apply for bulk operations
- SSH version requires proper SSH key setup
- May require specific Git version for advanced features

## Getting Help

### Documentation

- Check script comments for detailed operation information
- Review GitHub API documentation for advanced usage
- Examine log output for troubleshooting information

### Support Resources

- Use --help option where available
- Check GitHub documentation for API usage
- Verify Git installation and configuration
- Ensure proper network connectivity and authentication

### Common Issues

- Authentication failures: Verify GitHub tokens and SSH keys
- Network connectivity: Check internet access and GitHub availability
- Permission denied: Verify repository access rights
- Rate limiting: Wait for rate limit reset or reduce operation frequency
- Git configuration: Ensure proper Git user and email configuration

## Legal Disclaimer

This software is provided "as is" without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.

Use this software at your own risk. No warranty is implied or provided.

**By Shadd**
