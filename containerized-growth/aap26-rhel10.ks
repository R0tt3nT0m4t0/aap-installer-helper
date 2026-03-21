#version=RHEL10
# Use graphical install
graphical
reboot
%addon com_redhat_kdump --enable --reserve-mb='auto'
%end
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8


network  --bootproto=dhcp --device=enp1s0 --ipv6=auto --activate
network  --hostname=aap26.home.lab

repo --name="AppStream" --baseurl=file:///run/install/repo/AppStream

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

%end

firstboot --enable
ignoredisk --only-use=vda

#autopart
part /boot/efi --fstype="efi" --size=600
part /boot --fstype="xfs" --size=1024
part pv.01 --grow --size=1
volgroup vg_aap pv.01
logvol / --fstype="xfs" --name=lv_root --vgname=vg_aap --size=40960
logvol /var --fstype="xfs" --name=lv_var --vgname=vg_aap --grow --size=1
logvol swap --name=lv_swap --vgname=vg_root --size=8192

# Partition clearing information
clearpart --none --initlabel

# System timezone
timezone America/Chicago --utc

# Root password
rootpw --iscrypted --allow-ssh $y$j9T$QckUVoFdkuzwz3HChJFDvXJT$Vp9qCe62hA2aZ9DsOiUu2NigwjgjcI.GF/uHtjCtjw3
user --groups=wheel --name=jumedina --password=$y$j9T$uTyZl9Ls5Kl8mXMqzGWuQ4no$UPtj4Cy1HrSakHasXBsd5spgAHIKKKjxG5ObSJFGSo2 --iscrypted --gecos="Juan Medina"

firewall --enabled --service=ssh,http,https
selinux --enforcing

%post --log=/root/ks-post.log
# Update all packages
dnf -y update

# Pre-create the directory for AAP installer
mkdir -p /opt/aap-installer

# Optional: Allow jumedina to sudo without a password (useful for automation labs)
echo "jumedina ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/jumedina
chmod 0440 /etc/sudoers.d/jumedina
%end

