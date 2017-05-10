brew install dnsmasq
sudo cp dnsmasq.conf /usr/local/etc/dnsmasq.conf
sudo cp -v $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons/
sudo mkdir /etc/resolver
sudo bash -c 'echo "nameserver 192.168.72.102" > /etc/resolver/ycloud.dev'
sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
