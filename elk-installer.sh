###Install Dependencies###

echo "------Installing Dependencies------" 
timedatectl set-timezone EST
apt-get install default-jre -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt-get update

###Install ELK Stack###

clear
echo "------Installing ELK Stack------"
apt-get -y install elasticsearch logstash kibana
systemctl enable elasticsearch
systemctl enable logstash
systemctl enable kibana
service elasticsearch start
/usr/bin/elasticsearch/bin/elasticsearch-setup-passwords -interactive
/usr/bin/elasticsearch/bin/elasticsearch-certutil ca --pem
###UNZIP FILE AND PLACE IN /CA###########
###Install Filebeat###

clear
echo "------Installing Filebeat------"
apt-get -y install filebeat
filebeat modules enable suricata
filebeat modules enable system
filebeat modules enable netflow
systemctl enable filebeat

###Install & Configure pfELK for PFSense Firewall Logs###

clear
echo "------Installing & Configuring pfELK------"
add-apt-repository ppa:maxmind/ppa
apt update
apt install geoipupdate -y

#--Edit GeoIP Config--#
clear
echo "Please edit GEOIP config as follows:"
echo
echo "Add Account Login Info"
echo "EditionIDs GeoLite2-City GeoLite2-Country GeoLite2-ASN"
echo "Uncomment DatabaseDirectory Line"
sleep 10 && nano /etc/GeoIP.conf

echo "00 17 * * 0 geoipupdate" >  /etc/cron.weekly/geoipupdate
geoipupdate
cd
git clone https://github.com/3ilson/pfelk
cp -r pfelk/etc/logstash/conf.d/* /etc/logstash/conf.d/
mkdir -p /etc/pfELK/logs/
wget https://raw.githubusercontent.com/3ilson/pfelk/master/error-data.sh -P /etc/pfELK/
chmod +x /etc/pfELK/error-data.sh
echo
echo "Installation Completed"
echo
echo "To Complete Setup:"
echo "1. Drop the custom config files into their respective directories"
echo "2. Start ELK services"
echo "3. Enter passwords in configs"
echo "4. Setup filebeat dashboards with 'filebeat setup -e'"
echo "5. Create logstash user in Kibana as outlined here: https://www.elastic.co/guide/en/logstash/current/ls-security.html"
echo "6. Create normal user to view dashboards in Kibana"
echo "7. Set PFSense to send firewall logs IP:5141 and netflow data to IP:2055"

