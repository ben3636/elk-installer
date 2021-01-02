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

#--Install Filebeat--#
clear
echo "------Installing Filebeat------"
apt-get -y install filebeat
filebeat modules enable suricata
filebeat modules enable system
filebeat modules enable netflow
systemctl enable filebeat

#--Setup Filebeat--#
clear
echo "------Setting Up Filebeat------"
service elasticsearch restart
service kibana start
filebeat setup -e
service kibana stop
#apt install rsyslog -y #If Filebeat doesn't ship any logs on Ubuntu Server, syslog may need to be installed
echo "xpack.security.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
service elasticsearch restart

##--Set Up Elasticsearch Authentication--#
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive
/usr/share/elasticsearch/bin/elasticsearch-certutil ca --pem
apt install unzip -y
unzip /usr/share/elasticsearch/elastic-stack-ca.zip
mv ca /

###Install & Configure pfELK for PFSense Firewall Logs###

clear
echo "------Installing & Configuring pfELK------"
add-apt-repository ppa:maxmind/ppa
apt update
apt install geoipupdate -y

#--Edit GeoIP Config--#
mv /root/elk-installer/GeoIP.conf /etc
clear
echo "Please Add Account Login Info"
sleep 10
nano /etc/GeoIP.conf
clear
echo "00 17 * * 0 geoipupdate" >  /etc/cron.weekly/geoipupdate
geoipupdate
cd
git clone https://github.com/3ilson/pfelk
cp -r pfelk/etc/logstash/conf.d/* /etc/logstash/conf.d/
mkdir -p /etc/pfELK/logs/
wget https://raw.githubusercontent.com/3ilson/pfelk/master/error-data.sh -P /etc/pfELK/
chmod +x /etc/pfELK/error-data.sh

###Place Custom Config Files & Add Passwords###

mv elk-installer/ELK\ Custom\ Config\ Files/filebeat/filebeat.yml /etc/filebeat/
mv elk-installer/ELK\ Custom\ Config\ Files/filebeat/modules.d/* /etc/filebeat/modules.d/
mv elk-installer/ELK\ Custom\ Config\ Files/kibana/kibana.yml /etc/kibana/
mv elk-installer/ELK\ Custom\ Config\ Files/logstash/logstash.yml /etc/logstash/
mv elk-installer/ELK\ Custom\ Config\ Files/logstash/conf.d/* /etc/logstash/conf.d/
echo "Now you'll have to update the configs with the passwords you set..."
sleep 5
echo "First, add the password for the logstash_interal user to the Logstash output file (you'll create this user in Kibana shortly)"
sleep 5
nano /etc/logstash/conf.d/50-outputs.conf
clear
echo "Now update the kibana_system user's password in the Kibana config"
sleep 5
nano /etc/kibana/kibana.yml
clear
echo "Now update the 'elastic' user's password in the Filebeat config"
sleep 5
nano /etc/filebeat/filebeat.yml
clear
echo "Starting Everything Up..."
service elasticsearch start
service logstash start
service kibana start
service filebeat start
clear
echo "To Complete Setup:"
echo "1. Add templates and saved objects to Kibana as shown here: http://pfelk.3ilson.com"
echo "2. Create logstash_internal user in Kibana as outlined here: https://www.elastic.co/guide/en/logstash/current/ls-security.html (USE THE PASSWORD YOU ALREADY SET)"
echo "3. Create standard role/user to view dashboards in Kibana"
echo "4. Set PFSense to send firewall logs IP:5141 and netflow data to IP:2055"
