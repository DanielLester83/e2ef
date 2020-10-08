#!/bin/bash/
echo "Note: This is a script designed to be run directly on a linux debian terminal NOT THROUGH SSH"
while [ ! $remail ]
do
    echo Input the RECIEVING email address:
    read remail
done
while [ ! $semail ]
do
    echo Input the SENDING email address:
    read $semail
done
while [ ! $spass ]
do
    echo "Input the SENDING email password (Note for gmail See: https://myaccount.google.com/lesssecureapps)":
    read $spass
done
while [ ! $passphrase ]
do
    echo "Input the PRIVATE KEY PASSPHRASE":
    read $passphrase
done
while [ ! $url ]
do
    echo "Input the SENDING email smtp url (Note for gmail it is smtps://smtp.gmail.com:465":
    read $url
done
while [ ! $tail ]
do
    echo "Input a SIBJECT TAIL if you wish (can be blank, but I recommend something like (SERVER) as it helps sort emails as the subjects are not encrypted)":
    read $tail
done


if id "e2ef" &>/dev/null;
then
    echo 'e2ef user already exisis, therefore I assume this script has already been and wont procved'
    exit
else
     sudo adduser --system --no-create-home --disabled-login e2ef
     #mkdir -p /var/lib/zeyple/keys && chmod 700 /var/lib/zeyple/keys && chown zeyple: /var/lib/zeyple/keys
     #sudo -u zeyple gpg --homedir /var/lib/zeyple/keys --keyserver hkp://keys.gnupg.net --search you@domain.tld # repeat for each key
     sudo cp e2ef.py /usr/local/bin/e2ef.py
     sudo chmod 744 /usr/local/bin/e2ef.py
     sudo chown e2ef: /usr/local/bin/e2ef.py
     sudo sed -i -e "/##REMAIL##/$remail/" /usr/local/bin/e2ef.py
     sudo sed -i -e "/##SEMAIL##/$semail/" /usr/local/bin/e2ef.py
     sudo sed -i -e "/##RPASS##/$spass/" /usr/local/bin/e2ef.py
     sudo sed -i -e "/##PASSPHRASE##/$passphrase/" /usr/local/bin/e2ef.py
     sudo sed -i -e "/##URL##/$url/" /usr/local/bin/e2ef.py
     sudo sed -i -e "/##TAIL##/$tail/" /usr/local/bin/e2ef.py
fi

if ! command -v gpg; then sudo apt-get install gpg
sudo -u e2ef gpg --import import.asc
if $? != 0;
then
    echo "No import.asc keyfile found, therefore creating one now.\n YYou will prompted to answer several questions\n"
    echo "YOU MUST TYPE IN THE SENDING EMAIL EXACTLY AS BEFORE\N"
    echo "\nRecommended answers: 9 1 0 Y SENDING_EMAILS_NAME SENDING_EMAIL COMNENT O(kay) GREAT_UNIQUE_KEYFILE_PASSWORD THIS_COMPUTERS_PASSWORD\n"
    sudo -u e2ef gpg --expert --full-gen-key
    sudo -u e2ef gpg --output public.asc --armor --export $semail
    sudo -u e2ef gpg --output private.asc --armor --export-secret-key $semail
fi

if ! command -v curl; then sudo apt-get install curl
if ! command -v python; then sudo apt-get install python
if ! command -v postfix
then
    sudo apt-get install postfix
    #postconf | grep config_directory
    echo "content_filter = e2ef"  >> /etc/postfix/main.cf
    sed -i -e "1izeyple unix - n n - - pipe user=e2ef argv=/usr/local/bin/e2ef.py $remail\n#shoukd be change to \${recipient} in future version" /etc/postfix/master.cf
#    sed -i -e "1i$remail\n" ~/.forward
    service postfix reload


else
    echo "Postfix already installed. Assuming it is already properly configured"
fi
while [ $answer != "yes" && $answer != "no" ]
do
    echo "Do you wish to have logs about to be rotated out emailed to you?[yes|no]"
    read answer
done
if $answer = "yes" then sed -i -e '/{/amail root' /etc/logrotate.d/*
while [ $answer != "yes" && $answer != "no" ]
do
    echo "Do you wish to be emailed every time someone logs in or out?[yes|no]"
    read answer
done
if $answer = "yes"
then
    sudo cp pam_session.sh /usr/local/bin/
    sudo sed -i '/^UsePAM/{h;s/.*/UsePAM Yes/};${x;/^$/{s//UsePAM Yes/;H};x}' /etc/ssh/sshd_config
    sudo echo "session required        pam_exec.so quiet seteuid /usr/local/bin/pam_session.sh" >> /etc/pam.d/common-session
fi
