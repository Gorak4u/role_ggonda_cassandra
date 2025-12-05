#!/bin/bash
set -e

# Detect OS and version
if [ -f /etc/redhat-release ]; then
  OS_MAJOR_VERSION=$(grep -oE '[0-9]+\.' /etc/redhat-release | cut -d'.' -f1)
  if [ "$OS_MAJOR_VERSION" -eq 7 ]; then
    OS_FAMILY="el7"
    PUPPET_AGENT_RPM="https://yum.puppet.com/puppet6-release-el-7.noarch.rpm"
  elif [ "$OS_MAJOR_VERSION" -eq 8 ]; then
    OS_FAMILY="el8"
    PUPPET_AGENT_RPM="https://yum.puppet.com/puppet6-release-el-8.noarch.rpm"
  elif [ "$OS_MAJOR_VERSION" -eq 9 ]; then
    OS_FAMILY="el9"
    PUPPET_AGENT_RPM="https://yum.puppet.com/puppet6-release-el-9.noarch.rpm"
  else
    echo "Unsupported RHEL/CentOS version: $OS_MAJOR_VERSION"
    exit 1
  fi
else
  echo "Unsupported OS. This script is for RHEL/CentOS systems (EL7, EL8, EL9)."
  exit 1
fi

echo "Detected OS: RHEL/CentOS $OS_MAJOR_VERSION"

# Install Puppet Agent
echo "Installing Puppet Agent..."
rpm -Uvh --force $PUPPET_AGENT_RPM || echo "Puppet agent RPM already installed or failed, attempting yum install..."
yum install -y puppet-agent

# Ensure puppet-agent is in PATH for later commands
export PATH=$PATH:/opt/puppetlabs/bin

# Install Git
echo "Installing Git..."
yum install -y git

# Create required directories for Puppet environment
echo "Creating Puppet environment directories..."
mkdir -p /etc/puppetlabs/code/environments/production/modules
mkdir -p /etc/puppetlabs/code/environments/production/data

# Clone/Checkout role and profile repos
echo "Cloning role_ggonda_cassandra repository..."
# !!! REPLACE WITH YOUR ACTUAL GIT REPO URL !!!
if [ ! -d "/etc/puppetlabs/code/environments/production/modules/role_ggonda_cassandra" ]; then
  git clone https://YOUR_GIT_REPO_URL/role_ggonda_cassandra.git /etc/puppetlabs/code/environments/production/modules/role_ggonda_cassandra
  (cd /etc/puppetlabs/code/environments/production/modules/role_ggonda_cassandra && git checkout main) # Or your default branch
else
  echo "role_ggonda_cassandra already cloned."
fi

echo "Cloning profile_ggonda_cassandr repository..."
# !!! REPLACE WITH YOUR ACTUAL GIT REPO URL !!!
if [ ! -d "/etc/puppetlabs/code/environments/production/modules/profile_ggonda_cassandr" ]; then
  git clone https://YOUR_GIT_REPO_URL/profile_ggonda_cassandr.git /etc/puppetlabs/code/environments/production/modules/profile_ggonda_cassandr
  (cd /etc/puppetlabs/code/environments/production/modules/profile_ggonda_cassandr && git checkout v2.1.0)
else
  echo "profile_ggonda_cassandr already cloned."
fi

echo "Cloning administration-hiera repository..."
# !!! REPLACE WITH YOUR ACTUAL GIT REPO URL !!!
if [ ! -d "/etc/puppetlabs/code/environments/production/data/administration-hiera" ]; then
  git clone https://YOUR_GIT_REPO_URL/administration-hiera.git /etc/puppetlabs/code/environments/production/data/administration-hiera
  (cd /etc/puppetlabs/code/environments/production/data/administration-hiera && git checkout main) # Or your default branch
else
  echo "administration-hiera already cloned."
fi

# Create hiera.yaml symlink in the environment
echo "Setting up Hiera configuration..."
if [ ! -L "/etc/puppetlabs/code/environments/production/hiera.yaml" ]; then
  ln -s /etc/puppetlabs/code/environments/production/data/administration-hiera/hiera.yaml /etc/puppetlabs/code/environments/production/hiera.yaml
else
  echo "hiera.yaml symlink already exists."
fi


# Run puppet apply
echo "Running puppet apply..."
puppet apply --modulepath=/etc/puppetlabs/code/environments/production/modules:/opt/puppetlabs/puppet/modules -e "include role_ggonda_cassandra" --hiera_config=/etc/puppetlabs/code/environments/production/hiera.yaml --detailed-exitcodes
APPLY_EXIT_CODE=$?

# Puppet apply --detailed-exitcodes returns:
# 0: The run succeeded with no changes or failures.
# 1: The run failed.
# 2: The run succeeded and some resources were changed.
# 4: The run succeeded and some resources failed.
# 6: The run succeeded, some resources changed, and some resources failed.

if [ "$APPLY_EXIT_CODE" -eq 0 ] || [ "$APPLY_EXIT_CODE" -eq 2 ]; then
  echo "Puppet apply completed successfully."
  exit 0
else
  echo "Puppet apply failed with exit code $APPLY_EXIT_CODE."
  exit 1
fi
