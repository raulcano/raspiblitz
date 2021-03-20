#!/bin/bash

SliderVersion="v0.1"
ServerPort=13425
StartupPage="http://127.0.0.1"
# StartupPath=""
StartupPath="#/carousel"

# command info
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "-help" ]; then
  echo "# config script to switch My First App on or off"
  echo "# bonus.slider.sh [on|off|menu]"
  echo "# installs Slider $SliderVersion"
  exit 1
fi

source /mnt/hdd/raspiblitz.conf
source /home/admin/raspiblitz.info

# switch on
if [ "$1" = "1" ] || [ "$1" = "on" ]; then

    echo "# *** INSTALL APP ***"
    # create app user
    sudo adduser --disabled-password --gecos "" slider 2>/dev/null

    # add local directory to path and set PATH for the user
    # export PATH=$PATH:/home/slider/.local/bin
    sudo bash -c "echo 'PATH=\$PATH:/home/slider/.local/bin' >> /home/slider/.profile"
    sudo bash -c "echo 'PATH=\$PATH:/home/slider/.local/share/composer' >> /home/slider/.profile"
    
    
    # PHP
    echo ""
    echo "# ***"
    echo "# Installing PHP 7.3..."
    echo "# ***"
    echo ""
    sudo apt-get -y install -y php7.3-common php7.3-fpm php7.3-cli php7.3-curl php7.3-json php7.3-mysql php7.3-opcache php7.3-gd php7.3-sqlite3 php7.3-mbstring php7.3-zip php7.3-readline php-pear
    
    # Composer
    echo ""
    echo "# ***"
    echo "# Installing composer..."
    echo "# ***"
    echo ""
    
    # sudo -u slider curl -sS https://getcomposer.org/installer | php ; mv composer.phar /home/slider/.local/bin/composer ; composer self-update
    sudo -u slider curl -sS https://getcomposer.org/installer | php
    sudo -u slider php composer.phar self-update
    sudo mv composer.phar /home/slider/.local/share/composer

    echo ""
    echo "# ***"
    echo "# Downloading app source code..."
    echo "# ***"
    echo ""

    cd /home/slider
    sudo -u slider git clone https://github.com/raulcano/raspiblitz-laravel-app.git 2>/dev/null

    cd /home/slider/raspiblitz-laravel-app
    echo ""
    echo "# ***"
    echo "# Unzipping vendor packages..."
    echo "# ***"
    echo ""
    sudo -u slider unzip -q vendor.zip
    sudo -u slider touch database/database.sqlite
    
    sudo -u slider php /home/slider/.local/share/composer/composer.phar install
    sudo -u slider php artisan key:generate
    sudo -u slider php artisan migrate
    
    # copy the necesary config files into the storage folder
    sudo cp /mnt/hdd/raspiblitz.conf /home/slider/raspiblitz-laravel-app/storage/app/raspiblitz.conf
    sudo cp /home/admin/raspiblitz.info /home/slider/raspiblitz-laravel-app/storage/app/raspiblitz.info

    echo ""
    echo "# ***"
    echo "# Starting the server in port $ServerPort..."
    echo "# ***"
    echo ""
    # !!!!
    #  
    # CREATE A SERVICE TO RUN THE SERVER, INSTEAD OF STARTING THE SERVER HERE
    # 
    # !!!!
    sudo -u slider php artisan serve --port=$ServerPort&

    
    # Install the X window system
    
    sudo apt-get -y install xserver-xorg
    sudo apt-get -y install xinit
    sudo apt-get -y install xorg
    
    # Install Chromium and kiosk dependencies
    sudo apt-get -y install chromium-browser
    sudo apt-get -y install matchbox-window-manager xautomation unclutter

    # Create the chromium startup script

    echo "#!/bin/sh
matchbox-window-manager -use_cursor no &
chromium-browser $StartupPage:$ServerPort/$StartupPath \
  --no-sandbox \
  --start-fullscreen \
  --kiosk \
  --incognito \
  --disable-translate \
  --fast \
  --fast-start \
  --disable-infobars \
  --disable-features=TranslateUI \
  --hide-scrollbars \
  " | sudo -u slider tee -a /home/slider/start-chromium.sh
    
    sudo -u slider chmod +x start-chromium.sh
    
#     # Add the kiosk script to .bashrc (this is if we want to run this on startup)
#     # sudo bash -c "echo 'xinit /home/slider/start-chromium.sh' >> /home/slider/.bashrc"
    

    echo "# ***"
    echo "# Starting Chromium in Kiosk mode..."
    echo "# ***"

    sudo xinit /home/slider/start-chromium.sh

  exit 0
fi

# switch off
if [ "$1" = "0" ] || [ "$1" = "off" ]; then
  # isInstalled=$(sudo ls /etc/systemd/system/slider.service 2>/dev/null | grep -c 'slider.service')
  isInstalled=1
  if [ ${isInstalled} -eq 1 ]; then
    
    echo "# *** REMOVING Slider ***"

    # echo "# ***"
    # echo "# Deactivating the Python environment"
    # echo "# ***"
    # sudo -u slider deactivate

    # echo "# ***"
    # echo "# Removing all files within the app directory: '/home/slider' ..."
    # echo "# ***"
    # sudo -u slider rm -r /home/slider
    # Raspiblitz removes the app folder automatically

    # delete user
    sudo userdel -rf slider 2>/dev/null


    echo "# OK Slider removed."
  else
    echo "# Slider is not installed."
  fi
  exit 0
fi