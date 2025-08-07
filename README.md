# GitTools

A collection of enhanced shell scripts for streamlined GitHub project creation and management. These tools provide automated repository setup with robust authentication, error handling, and modern Git practices.

## 🚀 Features

- **Dual Authentication Methods**: Support for both Personal Access Tokens (HTTPS) and SSH keys
- **Enterprise GitHub Support**: Compatible with GitHub.com and GitHub Enterprise instances
- **Intelligent Error Handling**: Comprehensive validation and error recovery
- **Modern Git Practices**: Uses `main` as default branch, proper commit handling
- **Interactive Setup**: User-friendly prompts with clear instructions
- **Colorized Output**: Enhanced terminal experience with status indicators

## 📁 Tools Overview

### 1. CreateGitHubProject.sh
**Primary GitHub project creation tool using HTTPS authentication**

- Uses Personal Access Token for authentication
- Supports both GitHub.com and GitHub Enterprise
- Automatic repository initialization and configuration
- Intelligent file detection and commit handling
- Comprehensive error checking and validation

### 2. CreateGitHubProject-SSH.sh
**SSH-based GitHub project creation tool**

- Uses SSH key authentication for enhanced security
- SSH key validation and connection testing
- Same feature set as HTTPS version with SSH benefits
- Ideal for environments with established SSH key infrastructure

## 🛠️ Prerequisites

### For Both Tools:
- **Git**: Version 2.0 or higher
- **Bash**: Version 4.0 or higher
- **curl**: For API interactions
- **jq**: For JSON parsing (recommended)

### For HTTPS Version (CreateGitHubProject.sh):
- **GitHub Personal Access Token** with appropriate permissions:
  - `repo` (Full control of private repositories)
  - `public_repo` (Access to public repositories)
  - `delete_repo` (Delete repositories - optional)

### For SSH Version (CreateGitHubProject-SSH.sh):
- **SSH Key** configured with your GitHub account
- SSH agent running with key loaded
- Access to GitHub via SSH (test with `ssh -T git@github.com`)

## 🚀 Quick Start

### Using HTTPS Authentication

1. **Generate a Personal Access Token**:
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Generate new token with `repo` scope
   - Copy the token (you won't see it again!)

2. **Run the script**:
   ```bash
   chmod +x CreateGitHubProject.sh
   ./CreateGitHubProject.sh
   ```

3. **Follow the prompts**:
   - GitHub domain (press Enter for github.com)
   - Full path to your local project directory
   - GitHub username
   - Personal access token

### Using SSH Authentication

1. **Set up SSH keys** (if not already configured):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ssh-add ~/.ssh/id_ed25519
   ```

2. **Add SSH key to GitHub**:
   - Copy public key: `cat ~/.ssh/id_ed25519.pub`
   - Add to GitHub Settings → SSH and GPG keys

3. **Run the script**:
   ```bash
   chmod +x CreateGitHubProject-SSH.sh
   ./CreateGitHubProject-SSH.sh
   ```

## 📋 Usage Examples

### Example 1: Creating a New Project on GitHub.com
```bash
./CreateGitHubProject.sh

# Prompts:
# GitHub domain: [press Enter]
# Project path: /home/user/my-awesome-project
# Username: myusername
# Token: ghp_xxxxxxxxxxxxxxxxxxxx
```

### Example 2: Enterprise GitHub Instance
```bash
./CreateGitHubProject.sh

# Prompts:
# GitHub domain: github.company.com
# Project path: /home/user/enterprise-project
# Username: john.doe
# Token: your_enterprise_token
```

### Example 3: SSH with Custom Configuration
```bash
./CreateGitHubProject-SSH.sh

# The script will:
# 1. Test SSH connectivity
# 2. Validate your SSH key setup
# 3. Create repository using SSH authentication
```

## 🔧 Configuration Options

### GitHub Enterprise Setup
Both scripts automatically detect and configure:
- **API Endpoints**: Adjusts API URLs for enterprise instances
- **SSH Hosts**: Configures proper SSH hostnames
- **Authentication**: Adapts authentication methods per instance

### Repository Settings
The scripts configure repositories with:
- **Default Branch**: `main` (modern Git standard)
- **Initial Commit**: Automatic with timestamp
- **Remote Origin**: Properly configured for chosen authentication method
- **Branch Tracking**: Sets up proper upstream tracking

## 🛡️ Security Best Practices

### Personal Access Tokens
- **Scope Limitation**: Use minimal required scopes
- **Rotation**: Regularly rotate tokens
- **Storage**: Never commit tokens to repositories
- **Environment Variables**: Consider using environment variables for automation

### SSH Keys
- **Key Type**: Use Ed25519 keys for better security
- **Passphrase**: Always use a strong passphrase
- **Agent**: Use SSH agent for secure key management
- **Rotation**: Regularly rotate SSH keys

## 🔍 Troubleshooting

### Common Issues and Solutions

#### Authentication Failures
```bash
# Check token permissions
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user

# Test SSH connectivity
ssh -T git@github.com
```

#### Repository Already Exists
- The script will detect existing repositories
- Options to continue with existing repo or choose different name
- Automatic conflict resolution

#### Network Connectivity
- Scripts validate network connectivity
- Clear error messages for network issues
- Retry mechanisms for transient failures

#### Permission Issues
- Validate directory permissions
- Check Git configuration
- Verify GitHub account permissions

### Debug Mode
Enable debug mode for detailed troubleshooting:
```bash
bash -x CreateGitHubProject.sh
```

## 📊 Script Features Comparison

| Feature | HTTPS Version | SSH Version |
|---------|---------------|-------------|
| Authentication | Personal Access Token | SSH Key |
| Enterprise Support | ✅ | ✅ |
| Error Handling | ✅ | ✅ |
| Interactive Setup | ✅ | ✅ |
| SSH Key Validation | ❌ | ✅ |
| Token Validation | ✅ | ❌ |
| Network Testing | ✅ | ✅ |
| Colorized Output | ✅ | ✅ |

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** thoroughly on multiple environments
4. **Submit** a pull request with clear description

### Development Setup
```bash
git clone https://github.com/yourusername/GitTools.git
cd GitTools
chmod +x *.sh
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
- **GitHub Issues**: Report bugs and feature requests
- **Documentation**: Check this README and inline script comments
- **Community**: Join discussions in the repository

## 🔄 Version History

- **v2.0**: Added SSH support and enhanced error handling
- **v1.5**: Enterprise GitHub support
- **v1.0**: Initial release with HTTPS authentication

## 🌟 Acknowledgments

- Inspired by the need for streamlined GitHub workflows
- Built with modern shell scripting best practices
- Community feedback and contributions

---

**Made with ❤️ for developers who love automation**
