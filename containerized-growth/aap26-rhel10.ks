#version=RHEL10
graphical
reboot
#====================================================
%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
#====================================================
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8
network  --bootproto=dhcp --device=enp1s0 --ipv6=auto --activate
network  --hostname=aap26.home.lab

#===================================
%packages
@^minimal-environment
tar
python3
python3-pip
curl
wget
vim
git-core
rsync
policycoreutils-python-utils
sudo
tree
ansible-core
%end
#===================================

firstboot --enable
ignoredisk --only-use=vda

# Partition clearing information
zerombr
clearpart --all --initlabel --disklabel=gpt

#autopart
# UEFI Specific Partitioning
part /boot/efi --fstype="efi" --size=600 --ondisk=vda
part /boot     --fstype="xfs" --size=1024 --ondisk=vda
part pv.01     --grow --size=1 --ondisk=vda

# Filesystem Partitioning
volgroup vg_root pv.01
logvol /      --fstype="xfs" --name=lv_root   --vgname=vg_root --size=40960
logvol /home  --fstype="xfs" --name=lv_home   --vgname=vg_root --size=40960
logvol /var   --fstype="xfs" --name=lv_var    --vgname=vg_root --grow --size=1
logvol swap --name=lv_swap --vgname=vg_root --size=8192

# System timezone
timezone America/Chicago --utc

# Root password
rootpw --iscrypted --allow-ssh $y$j9T$QckUVoFdkuzwz3HChJFDvXJT$Vp9qCe62hA2aZ9DsOiUu2NigwjgjcI.GF/uHtjCtjw3

user --name=jumedina --groups=wheel --password=$y$j9T$uTyZl9Ls5Kl8mXMqzGWuQ4no$UPtj4Cy1HrSakHasXBsd5spgAHIKKKjxG5ObSJFGSo2 --iscrypted --gecos="Juan Medina"
sshkey --username=jumedina "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMtjMZ+rq9P7CKoVvrkHWUaKs7v10TLqAxwlUnPE6UtI jumedina@redhat.com"

firewall --enabled --service=ssh,http,https
selinux --enforcing

# Red Hat Subscription Management
#rhsm --organization="15976080" --activationkey="jumedinakey" --connect-to-insights
rhsm --org="15976080" --activation-key="jumedinakey" --connect-to-insights

#====================================================================================
%post --log=/root/ks-post.log

# Update all packages
dnf -y upgrade

# Pre-create the directory for AAP installer and installation
mkdir -p /opt/aap-installer /var/lib/aap_containers
chown jumedina:jumedina /opt/aap-installer /var/lib/aap_containers

# Ensure SELinux allows Podman to write to the custom directory
semanage fcontext -a -t container_var_lib_t "/var/lib/aap_containers(/.*)?"
restorecon -R -v /var/lib/aap_containers

# Switch to the user to set up the link
sudo -u jumedina bash <<EOF
mkdir -p ~/.local/share
ln -s /var/lib/aap_containers ~/.local/share/containers
EOF

# Optional: Allow jumedina to sudo without a password (useful for automation labs)
echo "jumedina ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/jumedina
chmod 0440 /etc/sudoers.d/jumedina

%end
#====================================================================================

