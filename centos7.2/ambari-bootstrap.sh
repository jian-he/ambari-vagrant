echo "Installing Ambari server"
export REPOURL=http://s3.amazonaws.com/dev.hortonworks.com/ambari/centos7/3.x/BUILDS/3.0.0.0-650
wget -O /etc/yum.repos.d/ambari.repo $REPOURL/ambaribn.repo
yum install ambari-server -y
ambari-server setup -s
ambari-server start
echo "Ambari server started"

