# HDP-3 Vagrant Installation

These instructions will let you provision a hdp 3 cluster with native service support using vagrant on your local machine. You can literally copy and run all the commands or configs.

## Before Starting
Checkout `ambari-vagrant` repo. We'll use centos7.2 for the installation.
```
git clone https://github.com/jian-he/ambari-vagrant.git
cd ambari-vagrant/centos7.2
```
Append VM hosts to /etc/hosts
```
sudo -s bash -c "cat hosts >> /etc/hosts"
```

## Step 1 - Provision

Run below command from the centos7.2 home direcotory
```
./up.sh 3
```
This will take a while, it'll let vagrant bring up a hdp cluster with 3 nodes. Optonally, you can specify the number of nodes up to 10. I recommend to select 3 as that can avoid additional manual steps to edit the configs.
Once this is done, your ambari server should be brought up at http://c7201.ambari.apache.org:8080

## Step 2 - Deploy HDP-3 cluster with Ambari

Navigate to Ambari (http://c7201.ambari.apache.org:8080) to install the HDP cluster. Below instructions document the required manual steps, for all other unmentioned pages, just click `next` to continue.

##### Page ``Select Version``:
* remove all OSes except `redhat7`. 
* Found the last successful centos7 HDP-3 build in [RE repo](http://release.eng.hortonworks.com/portal/release/HDP/atlantic/3.0.0.0/). Build no. `3.0.0.0-219` is latest at the time of writing.
* Click the eye icon and get the `HDP repo url` and `HDP-UTILS repo url`
* Fill `HDP-3.0` section with your HDP repo url such as: ` http://s3.amazonaws.com/dev.hortonworks.com/HDP/centos7/3.x/BUILDS/3.0.0.0-219`
* Fill `HDP-UTILS-1.1.0.211`section with such as `http://s3.amazonaws.com/dev.hortonworks.com/HDP-UTILS-1.1.0.21/repos/centos7`
##### Page ``Install Options``
* Fill the Target Hosts with below information if you have only provisioned 3 hosts
    ```
    c7201.ambari.apache.org
    c7202.ambari.apache.org
    c7203.ambari.apache.org
    ```
* Select the `insecure_private_key` from centos7.2 home directory
##### Page ``Customize Services``
* In ``YARN -> Settings``, set `Node memory` and `Maximum Container Size (Memory)` to be larger or equal to `1024`
##### Page ``Choose Services``
* Select services `HDFS`, `YARN + MapReduce2`, `ZooKeeper`, `Hbase`

##### Page `Assign Slaves and Clients`
* Unselect `NFSGateway`, `Phoenix Query Server` as they are not required for testing.
* Select `all` for `DataNode`, `NodeManager`, `RegionServer` and `Client`.

### Edit Configurations
* After Ambari successfully installed HDP-3 cluster, set below configurations in YARN, HDFS, HBase components. `*` means Ambari has a different value set by default. You will need to add other new properties in the `Custom ` section. 

     **yarn-site.xml**

    | Name        | Value      |
    |-------------|------------|
    | *yarn.nodemanager.container-executor.class | org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor |
    | yarn.nodemanager.runtime.linux.docker.default-container-network | bridge |   
    | hadoop.registry.dns.bind-address | c7202.ambari.apache.org |
    | hadoop.registry.dns.bind-port | 53|   
    | hadoop.registry.dns.domain-name | ycloud.dev|  
    | hadoop.registry.dns.enabled | true| 
    | hadoop.registry.dns.zone-mask | 255.255.255.0  | 
    | hadoop.registry.dns.zone-subnet |172.17.0  |
    | yarn.webapp.ui2.enable | true |
    | yarn.timeline-service.http-cross-origin.enabled | true |
    | yarn.resourcemanager.webapp.cross-origin.enabled | true |
    | yarn.nodemanager.webapp.cross-origin.enabled | true |
    | *yarn.timeline-service.version | 2.0f |
    | *yarn.nodemanager.aux-services | mapreduce_shuffle,timeline_collector |
    | yarn.nodemanager.aux-services.timeline_collector.class | org.apache.hadoop.yarn.server.timelineservice.collector.PerNodeTimelineCollectorsAuxService |
    | yarn.system-metrics-publisher.enabled | true |
    | yarn.rm.system-metrics-publisher.emit-container-events | true |

     **core-site.xml**

    | Name        | Value      |
    |-------------|------------|
    | hadoop.http.cross-origin.enabled | `true` |
    | hadoop.http.cross-origin.allowed-origins | `*`                                           | 
    | hadoop.http.cross-origin.allowed-methods | `GET,POST,HEAD`                               |
    | hadoop.http.cross-origin.allowed-headers | `X-Requested-With,Content-Type,Accept,Origin` |
    | hadoop.http.cross-origin.max-age         | `1800` |

     **hbase-site.xml**

    | Name        | Value      |
    |-------------|------------|
    |*hbase.coprocessor.region.classes | org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint,org.apache.hadoop.yarn.server.timelineservice.storage.flow.FlowRunCoprocessor|
    

 ### Enabling Timeline Service v.2
 
 * Login into all the HBase installed machines and copy `hadoop-yarn-server-timelineservice-hbase-3.0.0.3.0.0.0-219.jar` into hbase lib:
 
 	```
 	sudo cp /usr/hdp/3.0.0.0-219/hadoop-yarn/hadoop-yarn-server-timelineservice-hbase-3.0.0.3.0.0.0-219.jar /usr/hdp/3.0.0.0-219/hbase/lib/
 	sudo cp /usr/hdp/3.0.0.0-219/hbase/conf/hbase-site.xml /usr/hdp/3.0.0.0-219/hadoop/etc/hadoop/
 	sudo chown yarn:hadoop /usr/hdp/3.0.0.0-219/hadoop/etc/hadoop/hbase-site.xml
 	```
 * Create a table in HBase. logging into any one of the HBase service installed machine. 
 
 	```
 	sudo su - -c "/usr/hdp/3.0.0.0-219/hbase/bin/hbase org.apache.hadoop.yarn.server.timelineservice.storage.TimelineSchemaCreator" hbase
 	```
 * Once table is created, cross verify that all table exists. Otherwise, previous command need to execute with -s options.
 
 	```
 	sudo su - -c "echo 'list'|hbase shell" hbase
 	```
   Output of above should contains following table names. This ensure that your table creation is success.
 
 	```
 	timelineservice.app_flow                                                        
 	timelineservice.application                                                     
 	timelineservice.entity                                                          
 	timelineservice.flowactivity                                                    
 	timelineservice.flowrun
 	```
 * Login into `c7202.ambari.apache.org`, assuming App Timeline Service daemon is running in this host and edit:
 	
 	```
 	sudo vi /usr/hdp/3.0.0.0-219/hadoop-yarn/bin/yarn.distro
 	```
   Replace class name `org.apache.hadoop.yarn.server.applicationhistoryservice.ApplicationHistoryServer ` with `org.apache.hadoop.yarn.server.timelineservice.reader.TimelineReaderServer` under `timelineserver` section. Note that this only temporary step as long as Ambari integrates with ATSv2.



### **Once above steps are done, restart `HDFS`, `YARN`, `HBase` services in Ambari.**
* Verify that ATSv2 is enabled by accessing below url. Note that hostname in the URL must be the same as App Timeline Server running host from Ambari.
   ```
   http://c7202.ambari.apache.org:8188/ws/v2/timeline
   ```
### Enabling docker on YARN
* Ssh into each host and edit `/etc/hadoop/conf/container-executor.cfg` with below 
    ```
    min.user.id=50 
    feature.docker.enabled=1
    ```
    **Note that currently this config will be reset every time you restart YARN service on this host. You will have to re-edit it if you do so!**
* Run below command on every host with your OKTA username and password to login. This will pull down the docker images for later testing. Note that until [YARN-5428](https://issues.apache.org/jira/browse/YARN-5428) gets resolved, we have to manually pull down the images.
    ```
    docker login registry.eng.hortonworks.com
    docker pull registry.eng.hortonworks.com/hortonworks/base-centos6:0.1.0.0-30
    ```

	
## Step 3 - Start Yarn-DNS, Yarn REST server
Select a host where you want to start Yarn-DNS and Yarn REST server. 
I recommend to pick `c7202.ambari.apache.org` as that can avoid additional steps to edit configs.
* Login to host `c7202`
    ```
    vagrant ssh c7202
    ```
* Start Yarn-DNS and Yarn Rest server as root
   ```
   sudo su - -c "yarn org.apache.hadoop.registry.server.dns.RegistryDNSServer > /tmp/registryDNS.log 2>&1 &" root
   sudo su - -c "/usr/hdp/current/hadoop-yarn-resourcemanager/sbin/yarn-daemon.sh start servicesapi" root
   ```
* Setup `/user/root` direcotry on hdfs, this directory is used for storing service specific definitions.
    ```
    sudo su hdfs
    hdfs dfs -mkdir /user/root
    hdfs dfs -chown root:hdfs /user/root
    ```
* `Optional` Pre-install slider framework jars to expedite app submission.

    ```
    sudo su hdfs
    yarn slider dependency --upload
    ``` 
#### Enabling CORS proxy for Yarn REST server
Since Yarn Rest server does not have CORS support, we need to install `CORS PROXY` on the host where Yarn REST server is running.
* Add below configs in `configs.env` which could be found with command `find /tmp -name *.env` on host `c7201.ambari.apache.org`. Open that `configs.env` and edit below configs.
  ```
  localBaseAddress: "c7202.ambari.apache.org:1337"
  timelineWebAddress: "c7202.ambari.apache.org:8188"
  rmWebAddress: "c7201.ambari.apache.org:8088"
  dashWebAddress: "c7202.ambari.apache.org:9191"
  ```
* Install `nodejs` and `npm` in `c7202.ambari.apache.org` where YARN REST server is running:
  ```
  sudo yum install epel-release
  sudo yum install nodejs
  sudo yum install npm
  sudo npm install -g corsproxy
  ```
* Run corsproxy as below
  ```
  CORSPROXY_HOST=c7202.ambari.apache.org corsproxy &
  ```

## Step 4 - Install DNSmasq on your mac

This is required to make Yarn-DNS serve the DNS queries for your cluster. Replace `ycloud.dev` with your own domain name in below commands as needed.

* Run `./installDNSmasq.sh` from folder `ambari-vagrant/centos7.2/` to install DNSmasq on your mac. Note that this script will pop up password for `sudo` permssion. 
* Verify Dnsmasq is working by looking for a resolver with domain `ycloud.dev` in the output of scutil
    ```
    scutil --dns
    ```
* Note that the script assumes you choose `c7202.ambari.apache.org` as the Yarn-DNS host and `ycloud.dev` as the value for `hadoop.registry.dns.domain-name` in previous config.  If you have different configs, you need to edit `installDNSmasq.sh` to replace your settings accordingly.

## Running the tests
This test lets you launch a centos6 docker container on YARN.
* Copy and paste below sample Json spec to [custom service deployment tab](http://c7201.ambari.apache.org:8088/ui2/#/yarn-deploy-service) and click `Deploy`. Or use [Postman](https://www.getpostman.com/) to post to this rest end point `http://c7202.ambari.apache.org:9191/services/v1/applications`
* A simple centos6 Json spec:
    ```json
    {
      "name": "ycloud-test",
      "components" : 
        [
          {
            "name": "CENTOS6",
            "number_of_containers": 1,
            "artifact": {
              "id": "registry.eng.hortonworks.com/hortonworks/base-centos6:0.1.0.0-30",
              "type": "DOCKER"
            },
            "launch_command": "/bootstrap/privileged-centos6-sshd",
            "resource": {
              "cpus": 1, 
              "memory": "256"
           }
          }
        ]
    }
    ```
* Check if app named `ycloud-test` is running and container is launched at (http://c7201.ambari.apache.org:8088/ui2).
* Check if Yarn-DNS is working by pinging the container. Replace the ContainerId below with your actual `ContainerId` and use `-` instead of `_`.  For example, if you have ContainerId as such `container_e03_1494449095838_0004_01_000002`, try:
    ```
    ping ctr-e03-1494449095838_0004-01-000002.ycloud.dev
    ```
* You are all set !

## Troubleshoot
* Try to reinstall `VirtualBox`, if you run into errors that cannot be resolved. Reinstalling `VirtualBox` will not lose existing VMs.
* If you see below errors, try to run `vagrant plugin uninstall vagrant-vbguest`
```
Copy iso file /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso into the box /tmp/VBoxGuestAdditions.iso
mount: /dev/loop0 is write-protected, mounting read-only
Installing Virtualbox Guest Additions 5.1.18 - guest version is 5.1.10
Verifying archive integrity... All good.
Uncompressing VirtualBox 5.1.18 Guest Additions for Linux...........
VirtualBox Guest Additions installer
Removing installed version 5.1.10 of VirtualBox Guest Additions...
Copying additional installer modules ...
Installing additional modules ...
vboxadd.sh: Building Guest Additions kernel modules.
Failed to set up service vboxadd, please check the log file
/var/log/VBoxGuestAdditions.log for details.
Redirecting to /bin/systemctl start  vboxadd.service
Redirecting to /bin/systemctl start  vboxadd-service.service
Job for vboxadd-service.service failed because the control process exited with error code. See "systemctl status vboxadd-service.service" and "journalctl -xe" for details.
```
* If `Components` page shows empty for the services, try accessing below url to verify if the data is actually posted into ATS. Note replace ApplicationId with your own Id.
   ```
   http://c7202.ambari.apache.org:8188/ws/v2/timeline/apps/application_1495138892714_0003/entities/COMPONENT?fields=ALL
   ```
