# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "generic/debian12"

  # Share an additional folder to the guest VM. 
  config.vm.synced_folder "/var/tmp", "/share", create:true, owner: "vagrant", group: "vagrant"

  # Enable VirtualBox GUI mode
  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.name = "VM_DEV"
    vb.memory = "26000" # Adjust memory allocation as needed
    vb.cpus = 4 # Adjust CPU allocation as needed
    vb.customize ["modifyvm", :id, "--clipboard-mode", "bidirectional"]
    vb.customize ["modifyvm", :id, "--mouse", "usbtablet"]
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    vb.customize ["modifyvm", :id, "--monitorcount", 2]  # Deux écrans par défaut
    # Disable Remote Display (VRDP)
    vb.customize ["modifyvm", :id, "--vrde", "off"]   
  end

  # Prepare files to be included into the VM 
  config.vm.provision "file", source: "scripts/.bash_custom", destination: "/home/vagrant/.bash_custom"
  config.vm.provision "file", source: "config/k9s.yaml", destination: "/home/vagrant/.config/k9s/config.yaml"
  config.vm.provision "file", source: "scripts/post-install-as-user.sh", destination: "/tmp/post-install-as-user.sh"
  config.vm.provision "file", source: "config/sysctl-custom.conf", destination: "/tmp/sysctl.d/99-custom.conf"
  config.vm.provision "file", source: "config/MemoryAnalyzer.ini", destination: "/var/tmp/MemoryAnalyzer.ini"
 
   # Provisioning script
   # All this script is executed AS ROOT (no need for sudo)
  config.vm.provision "shell", inline: <<-SHELL

    # Stop at the first error
    set -ex
    
    # Set DEBIAN_FRONTEND to noninteractive
    export DEBIAN_FRONTEND=noninteractive

     # [CUSTOM] Set here your custom Debian mirrors if want want to use corporate ones
     #echo 'APT::Get::Update::SourceListWarnings::NonFreeFirmware "false";' > /etc/apt/apt.conf.d/99no-nonfreefirmware-warning.conf
     #cp /etc/apt/sources.list{,.ini}
     #cat <<- EoF | tee /etc/apt/sources.list
#deb http://miroir.acme.com/debian bookworm main non-free-firmware
#deb http://miroir.acme.com/debian bookworm-updates main non-free-firmware
#EoF

    # Prepare scripts 
    mv /tmp/post-install-as-user.sh /usr/local/bin/post-install-as-user.sh && chmod +x /usr/local/bin/post-install-as-user.sh
    
    # [CUSTOM] Add GGP keys of your corporate Debian mirrors if any
    #wget -O- http://miroir.acme.com/miroir.app.asc 2>/dev/null | tee /etc/apt/trusted.gpg.d/miroir.app.asc
    
    # Update and install necessary language packages
    apt-get update
    apt-get install -y locales

    # Kernel customization
    mv /tmp/sysctl.d/99-custom.conf /etc/sysctl.d/99-custom.conf

    # [CUSTOM] Set locale, timezone and keyboard to French, change this for others locales, TZ or keyboard layout
    sed -i '/fr_FR.UTF-8/s/^# //g' /etc/locale.gen
    locale-gen fr_FR.UTF-8
    update-locale LANG=fr_FR.UTF-8
    sed -i 's/XKBLAYOUT=".*"/XKBLAYOUT="fr"/' /etc/default/keyboard
    dpkg-reconfigure -f noninteractive keyboard-configuration
    setupcon
    timedatectl set-timezone Europe/Paris
 
    # [CUSTOM] Remove here problematic packages (postfix is interactive)
    apt-get remove --purge -y postfix 

    # Global upgrade
    apt-get update && apt-get upgrade -y
    
    # Allow 'vagrant' to read /write into journald (with 'logger' for instance)
    usermod -aG systemd-journal vagrant

    # Graphical environement installation
    apt-get install -y --no-install-recommends gdm3 gnome-core gnome-tweaks openjdk-17-jdk dbus-x11 geany
    
    # Docker
    apt-get install -y docker.io 
    usermod -G docker vagrant

    # Maven
    apt-get install -y maven
    mvn -v

    # NPM
    apt-get install -y curl gnupg2 ca-certificates lsb-release
    curl -fsSL 'https://deb.nodesource.com/setup_20.x' | sudo -E bash -
    apt-get install -y nodejs
    npm -v

    # [CUSTOM] Add here hosted entries (prefer DNS)
    #echo "10.0.0.5 foo" >> /etc/hosts

    # VM performances analysis  (analyser avec `atop -r`)
    apt-get install -y atop
    systemctl enable atop

    # Limit journald size
    echo "SystemMaxUse=50M        # Limits total size of journal logs
SystemMaxFileSize=10M   # Limits size of each journal file
RuntimeMaxUse=50M       # Limits size for logs stored in memory
RateLimitInterval=30s
RateLimitBurst=1000
Storage=volatile" >> /etc/systemd/journald.conf
    systemctl restart systemd-journald

    # Various utilitaries
    # Haveged est is usefull to prevent freezes when using /dev/random
    apt-get install -y vim htop iotop lsof unzip locate rsync screen dnsutils tree secure-delete procinfo \
         net-tools parted powerline etckeeper jq curl wget multitail bc patch httpie xmlstarlet systemd-timesyncd \
         xdg-utils bash-completion iotop hdparm haveged linux-perf p7zip-full uuid pwgen cloc flameshot \
         graphviz thunar p7zip-full file-roller firefox-esr

    # Bruno
    apt-get install -y libxss1
    curl -L 'https://github.com/usebruno/bruno/releases/download/v1.33.1/bruno_1.33.1_amd64_linux.deb' -o /var/tmp/bruno.deb
    dpkg -i /var/tmp/bruno.deb
    rm /var/tmp/bruno.deb

    # JVisualVM
    curl -L 'https://github.com/oracle/visualvm/releases/download/2.1.10/visualvm_2110.zip' -o /tmp/visualvm.zip
    unzip /tmp/visualvm.zip -d /opt/
    ln -s /opt/visualvm_2110 /opt/visualvm

    # MAT (Memory Analyzer)
    curl -L 'https://mirror.ibcp.fr/pub/eclipse/mat/1.15.0/rcp/MemoryAnalyzer-1.15.0.20231206-linux.gtk.x86_64.zip' -o /tmp/mat.zip
    unzip /tmp/mat.zip -d /opt/   
    cp /var/tmp/MemoryAnalyzer.ini /opt/mat/ 
    
    # JMeter
    curl -L 'https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-5.6.3.tgz' -o /var/tmp/jmeter.tar.gz
    tar xzpvf /var/tmp/jmeter.tar.gz -C /opt

    # pgbadger (postgresql performance analysis)
    apt-get install -y pgbadger

    # Intellij IDEA CE
    curl -L 'https://download.jetbrains.com/idea/ideaIU-2024.2.3.tar.gz' -o /var/tmp/idea.tar.gz
    rm -rf /opt/idea-IC* 2>/dev/null | true
    tar xzpvf /var/tmp/idea.tar.gz -C /opt
    ln -s /opt/idea/bin/idea.sh /usr/local/bin/idea
    IDEA_VERSION=$(ls /opt/ | grep idea)
    cat <<- EoF | tee /usr/share/applications/idea.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=IntelliJ IDEA Community Edition
Icon=/opt/$IDEA_VERSION/bin/idea.png
Exec="/opt/$IDEA_VERSION/bin/idea.sh" %f
Categories=Development;IDE;
Terminal=false
EoF
 
    # DBeaver 
    curl -L 'https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb' -o /var/tmp/dbeaver.deb
    dpkg -i /var/tmp/dbeaver.deb
    rm /var/tmp/dbeaver.deb

    # VSCode
    curl -L 'https://vscode.download.prss.microsoft.com/dbazure/download/stable/dc96b837cf6bb4af9cd736aa3af08cf8279f7685/code_1.89.1-1715060508_amd64.deb' -o /var/tmp/code.deb
    dpkg -i /var/tmp/code.deb
    rm /var/tmp/code.deb
    
    # Start guest addons at startup
    mkdir -p ~vagrant/.config/autostart
    chown -R vagrant:vagrant ~vagrant/.config

    cat <<- EoF | tee ~vagrant/.config/autostart/vboxclient.desktop
[Desktop Entry]
Type=Application
Exec=sh -c "VBoxClient --clipboard; VBoxClient --draganddrop;"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=VBoxClient All Options
Comment=Start VBoxClient
EoF

    # K3S (local Kubernetes)
    curl -sfL 'https://get.k3s.io' | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 0644" sh -
    
    # K9S
    curl -L 'https://github.com/derailed/k9s/releases/download/v0.32.4/k9s_linux_amd64.deb' -o /var/tmp/k9s.deb
    dpkg -i /var/tmp/k9s.deb
    rm /var/tmp/k9s.deb
    chown -R vagrant:vagrant ~vagrant/.config/k9s
    
    # Source bash_custom into .bashrc
    if ! grep -q  "bash_custom" /home/vagrant/.bashrc; then
      echo -e "\n# Scripts custom\n. ~/.bash_custom" >> /home/vagrant/.bashrc
    fi

    # Log VM version
    date +%Y%m%d-%H%M | tee /etc/VERSION_VM_DEV

    # [CUSTOM] Disable swapping to avoid freezes. Remove this for VMs < 32 GiB.
    swapoff -a
    sed -i.bak '/swap/d' /etc/fstab
    rm -f /swapfile

    # Disable Gnome indexation (uses a lot of IO)
    # We replace Nautilus by Thunar as file manager as we didn't find a way to disable tracker-indexing while keeping Nautilus.
    apt-get remove -y tracker tracker-extract tracker-miner-fs

    # Cleanup
    apt-get update && apt-get upgrade -y && apt-get full-upgrade -y && apt-get autoremove -y --purge && apt-get autoclean

    # We're done
    reboot
    
  SHELL
end
