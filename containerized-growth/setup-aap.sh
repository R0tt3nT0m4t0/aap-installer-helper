#!/usr/bin/env bash
# Script: setup-aap.sh
# Location: /opt/aap-installer/

INSTALL_DIR="/opt/aap-installer"
cd "$INSTALL_DIR" || exit 1

echo "  AAP 2.6 Containerized Setup Helper            "

# Extract the package
TARBALL=$(ls ansible-automation-platform-containerized-setup-*.tar.gz 2>/dev/null | head -n 1)
if [ -z "$TARBALL" ]; then
    echo "Error: No AAP installer tarball found in $INSTALL_DIR"
    exit 1
fi
echo "Extracting $TARBALL..."
tar -xzvf "$TARBALL"

# Find the extracted directory (it changes based on version)
SETUP_DIR=$(ls -d */ | grep "ansible-automation-platform-containerized-setup" | head -n 1 | sed 's/\///')
if [ -z "$SETUP_DIR" ]; then
    echo "Error: Could not find extracted setup directory."
    exit 1
fi
echo "Found Setup Directory: $SETUP_DIR"
cd "$SETUP_DIR" || exit 1

# Modify the inventory-growth file
INV_FILE="inventory-growth"
if [ ! -f "$INV_FILE" ]; then
    echo "Error: $INV_FILE not found in $SETUP_DIR"
    exit 1
fi
FULL_HOSTNAME=$(hostname -f)
echo "Using Hostname: $FULL_HOSTNAME"

# Request Registry Credentials
read -p "Enter Red Hat Registry Username: " REG_USER
read -sp "Enter Red Hat Registry Password: " REG_PASS
echo -e "\n"

# Change all occurrences of "aap.example.org" to the full hostname
sed -i "s/aap.example.org/$FULL_HOSTNAME/g" "$INV_FILE"
# Change all occurrences of "<set your own>" to "redhat123"
sed -i "s/<set your own>/redhat123/g" "$INV_FILE"
# Inject Registry Credentials
# We use '#' as a delimiter for sed in case the password contains '/'
sed -i "s/registry_username=.*/registry_username=$REG_USER/" "$INV_FILE"
sed -i "s/registry_password=.*/registry_password=$REG_PASS/" "$INV_FILE"
echo "Inventory updated successfully."

ansible-playbook -i "$INV_FILE" ansible.containerized_installer.install

