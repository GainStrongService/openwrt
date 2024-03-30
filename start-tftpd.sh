#/bin/bash
sudo killall -9 atftpd
sudo atftpd --daemon `pwd`/bin/targets/ath79/generic/
