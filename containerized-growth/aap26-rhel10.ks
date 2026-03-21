#version=RHEL10
# Use graphical install
graphical

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=enp1s0 --ipv6=auto --activate
network  --hostname=aap26.home.lab

repo --name="AppStream" --baseurl=file:///run/install/repo/AppStream

%packages
@^minimal-environment

%end

# Run the Setup Agent on first boot
firstboot --enable

# Generated using Blivet version 3.10.0
ignoredisk --only-use=vda
autopart
# Partition clearing information
clearpart --none --initlabel

# System timezone
timezone America/Chicago --utc

# Root password
rootpw --iscrypted --allow-ssh $y$j9T$QckUVoFdkuzwz3HChJFDvXJT$Vp9qCe62hA2aZ9DsOiUu2NigwjgjcI.GF/uHtjCtjw3
user --groups=wheel --name=jumedina --password=$y$j9T$uTyZl9Ls5Kl8mXMqzGWuQ4no$UPtj4Cy1HrSakHasXBsd5spgAHIKKKjxG5ObSJFGSo2 --iscrypted --gecos="Juan Medina"

