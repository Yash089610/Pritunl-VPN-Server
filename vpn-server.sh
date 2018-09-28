#! /bin/bash
SERVER_NAME=bot-vpn-server
gcloud compute instances create $SERVER_NAME \
--machine-type "f1-micro" \
--image-family ubuntu-1804-lts \
--image-project "ubuntu-os-cloud" \
--boot-disk-size "10" \
--boot-disk-type "pd-standard" \
--boot-disk-device-name "vpn-server" \
--tags https-server,http-server \
--zone us-central1-f \
--labels ready=true \
--can-ip-forward \
--metadata startup-script='#! /bin/bash
sudo su -
cd /root
echo "[Unit]" >> /lib/systemd/system/mongod.service
echo "Description=database" >> /lib/systemd/system/mongod.service
echo "After=network.target" >> /lib/systemd/system/mongod.service
echo "[Service]" >> /lib/systemd/system/mongod.service
echo "User=mongodb" >> /lib/systemd/system/mongod.service
echo "ExecStart=/usr/bin/mongod --config /etc/mongod.conf" >> /lib/systemd/system/mongod.service
echo "[Install]" >> /lib/systemd/system/mongod.service
echo "WantedBy=multi-user.target" >> /lib/systemd/system/mongod.service
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list
echo "deb http://repo.pritunl.com/stable/apt xenial main" > /etc/apt/sources.list.d/pritunl.list
sudo tee -a /etc/apt/sources.list.d/pritunl.list << EOF
deb http://repo.pritunl.com/stable/apt bionic main
EOF
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
apt-get update
apt-get --assume-yes install pritunl-link
systemctl start pritunl mongod
systemctl enable pritunl mongod
# Collect setup key
echo "setup key follows:"
pritunl setup-key
'
IP=$(gcloud compute instances describe $SERVER_NAME --zone us-central1-f | grep natIP | cut -d: -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')
gcloud compute firewall-rules create vpn-allow-8787 --allow tcp:8787 --network default --priority 65535 --source-ranges $IP/32
gcloud compute firewall-rules create vpn-allow-3838 --allow tcp:3838 --network default --priority 65535 --source-ranges $IP/32
echo "VPN server will be available for setup at https://$IP in a few minutes."
