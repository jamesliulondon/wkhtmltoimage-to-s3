yum install -y xorg-x11-fonts-75dpi wget libpng libXrender libjpeg libXext python-pip
yum install -y xorg-x11-fonts-Type1
wget http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-centos6-amd64.rpm
rpm -Uvh wkhtmltox-0.12.2.1_linux-centos6-amd64.rpm

git clone https://github.com/s3tools/s3cmd.git
cd s3cmd && python setup.py install

echo "#### REMEMBER TO run configure access using s3cmd --configure"
echo "Keep an eye out for data usage: currently 3 days of usage could kill any mobile dataplan"
