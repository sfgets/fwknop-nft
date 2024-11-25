# How to setup Fwknop on openwrt using nftables

fwknop-nft is a script base that uses [fwknop](http://www.cipherdyne.org/fwknop/) to dynamically open and close port on a openwrt system using [nftables](https://openwrt.org/docs/guide-user/firewall/misc/nftables).

Note that fwknop does not support nftables directly, hence the need for this package. You could review the history of that 11 years old issue [here](https://github.com/mrash/fwknop/issues/107)

## Fwknop install 
### on the Router
To install fwknop on your OpenWrt system, first update your package lists and then install the fwknopd package using the following commands:

```sh
opkg update
opkg install fwknopd luci-app-fwknopd
```

### on the client
follow the instruction how to install the client on the official documentation [here](https://www.cipherdyne.org/fwknop/docs/fwknop-tutorial.html#install-fwknop)

## Usage

Copy scripts directory to /etc/fwknop/ folder  on your router and make scripts executable:

    mkdir -p /etc/fwknop
    cp -r scripts/* /etc/fwknop/ 
    chmod +x /etc/fwknop/*.sh

Create a key pair, and add a fwknop client/server configuration.

## Configuration

### On the client:
 First make sure you have fwknop client installed
```
    fwknop -k -A tcp/22 -D <server_address> --save-rc-stanza 
```
This will generate needed KEYs and will save them in ~/.fwknoprc under a new stanza using <server_address>

Copy the keys form ~/.fwknoprc on the router or just add those to below config and use it

### On the router:

Edit the `/etc/config/fwknop` file and set the following:

```
config global
        option uci_enabled '1'

config network
        option network 'wan'

config config
        option ENABLE_IPT_FORWARDING 'Y'
        option ENABLE_NAT_DNS 'Y'
config access
        option SOURCE 'ANY'
        option DESTINATION 'ANY'
        option KEY_BASE64 '<KEY in BASE64>'
        option HMAC_KEY_BASE64 '<HMAC in BASS64>'
        option REQUIRE_SOURCE_ADDRESS 'Y'
        option CMD_CYCLE_OPEN '/etc/fwknop/cmd-open.sh $SRC $PORT $PROTO'
        option CMD_CYCLE_TIMER 5
        option CMD_CYCLE_CLOSE '/etc/fwknop/cmd-close.sh $SRC $PORT $PROTO'
```
## Starting fwknop on the client

Make sure fwknopd is running on the router.

after running the command you should be able to open your router http page
```
    fwknop -n <server_address> -A tcp/80 -s -f 60
```
the command above will refer to saved stanza in .fwknoprc however will request opening port 80 via tcp using default source address.
This rule once created will be valid for 1 min (60 sec)

Consult the fwknop client manual for further instructions

## Customization
First make sure your openwrt is using nftables and check the existence of firewall4 templates.
```
nft --version && fw4 -q check
```
if both commands are successful you could continue, otherwise your firmware revision might be old and still using iptables.

Scripts are made to plug in to existing fw4 rulesets without permanently altering any file or other configuration on the router. This means the fwknop firewall rules are not permanent and will be lost upon firewall or router restart. 

The scripts have the logic to deal will the basic use case and will insert or create the missing chains and rules on every call that fwknop deamon makes to them. Or otherwise said on every authorized request from a client.

Both scrips define some defaults like:
- nft commands and aliases
- wan input chain
- fwknop chain where rules will be added
- last rule in input wan chain

If those differ on your router modify the scripts accordingly!

This involves changing the variable that defines the name of the chains used for handling network traffic.
To do this, locate the `DEFAULTCHAIN` variable in the scripts (`cmd-open.sh` and `cmd-close.sh`), and update its value to your desired firewall chain name. 

The same goes for `WANCHAIN` and `WANFINALRULE`

You can check wether those will match the existing by executing
```
nft -a list chain inet fw4 input_wan | grep drop_from_wan
```
your final rule in that chain should be looking similar to below
```
jump drop_from_wan # handle 346
```
Remember, the new chain name must be consistent across all configuration files and scripts to ensure proper functionality. 

After making these changes, test the scripts to ensure that the firewall rules are correctly applied according to the customized settings.



