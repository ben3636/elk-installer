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
clear
echo "Please edit the Kibana config as follows:"
echo '
server.port: 5601
server.host: “0.0.0.0”
'
sleep 10 && nano /etc/kibana/kibana.yml
systemctl enable elasticsearch
systemctl enable logstash
systemctl enable kibana
systemctl start elasticsearch
systemctl start logstash
systemctl start kibana

###Install Filebeat###

clear
echo "------Installing Filebeat------"
apt-get -y install filebeat
filebeat modules enable suricata
filebeat modules enable system
filebeat modules enable netflow
systemctl enable filebeat

#--Edit Filebeat Config File--##
clear
echo 'Please edit the Filebeat Kibana host to be: "localhost:5601”'
sleep 10 && nano /etc/filebeat/filebeat.yml

#--Edit Filebeat Suricata Module to Point to Logs--#
clear
echo "Please edit the Filebeat Suricata Module config as follows:"
echo
echo 'var.paths: ["/var/log/suricata/*/eve.json"]'
sleep 10 && nano /etc/filebeat/modules.d/suricata.yml

#--Edit Filebeat Netflow to Listen on 0.0.0.0--#
clear
echo "Please edit the Filebeat Netflow host to be: 0.0.0.0"
sleep 10 && nano /etc/filebeat/modules.d/netflow.yml
service filebeat stop
filebeat setup -e
systemctl start filebeat

###Prep for Suricata Logs Ingest###

clear
echo "------Prepping System for Suricata Logs Ingest------"
mkdir /var/log/suricata
echo “PermitRootLogin yes” >> /etc/ssh/sshd_config #Will be updated to use restricted key-based auth
service sshd restart
passwd root #Adds a password to the root user, use 'passwd -l root' to remove it

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
service logstash restart
echo
echo "Installation Completed"
