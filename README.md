# panosh


A small collection of shell scripts I use to manage Palo Alto firewalls.  Some of the initial scripts that I am publishing I think a lot of people can utilize and the coding rookies of the world, like myself, can see what's going on with it and modify it pretty simply to meet their needs.  The other coding folks will scoff and ask why didn't I use python.  ;)  See above.

Only tested using Ubuntu 18 and 20.

Also, there is no doubt that these could be better or utilize a better naming convention, but for now it works and is only annoying when you look under the hood.  Or maybe it isn't, but I have polished this turd as best I can for now.

The initial scripts published use all native tools but because we are parsing the PAN XML from the API calls, we need you to install xmllint.
  sudo apt-get install --yes libxml2

Email notifications are using sendmail, so you'll have to install sendmail and configure it.  I setup mine to forward mail, but your config will depend on your environment.

Also, you'll have to chmod +x the shell scripts to make them usable, but I'm guessing you knew that already.  If not, do it.


There are four initial scripts that are available

paloalto-var.sh
  A collection of variables being sourced from other scripts.  Update this file as needed for paths you prefer
  
paloalto-inventory.sh
  Creates the inventory list of firewalls when it doesn't exist, which will be the case when you first run any script.  It will ask you for the friendly name that you want to call the firewall (I usually use the actual hostname of the firewall), the IP address (that is accessible for management), the management TCP port (by default is 443, but if you have GlobalProtect running, it is changed to 4443 in the case of managing the firewall from an external interface), username, password.   It attempts to reach the firewall, generate and retrieve the API key.  If it is successful, it will store most of that info (minus username and password) in the inventory txt file for use later.  Obviously this file becomes highly sensitive once this info is kept in it.  Please ensure your firewall(s) are locked down for management on known good IP's, not just wide open to the inet.  An idea that is floating in my head is to encrypt or minimally encode the txt file or even just encode the API key, but for now this is what we have.
  This file does not use paloalto-var.sh so you'll have to modify this script as well for any path changes you want.

paloalto-reboot.sh
  A reboot script, pretty dangerous.
  This does not use the default inventory list, it references the rebootlist.txt.
  I have the following in crontab:
     00 03 * * * /home/username/panosh/paloalto-reboot.sh
  This will check to see if there are any firewalls in the rebootlist.txt (found in the $bounce path) and if so, then at the scheduled time (in my case, 0300 / 3:00AM) it will reboot firewalls.
  It sleeps for :30 min and then checks to see if the firewall is operational or not, and then will email you.  You may have to setup sendmail on your box to get email notifications.
  
paloalto-software-upgrade.sh
  My favorite and the one that caused me the most heartburn.  But it works pretty well, simplifies downloads and software installs.  Limited in some logic functionality but it will do the job.  It would be nice to make a decision on if a base image has been downloaded and/or is needed, but haven't got there.  So you just have to know that you need to do that.  I don't currently trust this to do multiple firewalls in a row unattended or otherwise, so I just do one at a time for now but I bet it could be massaged better.
  
  
paloalto-configs.sh
  Exports the device state and saves it as $hostname.tgz (which is based off the friendly name you give it in the inventory file).  This file can be used to restore the entire config to a new device should you ever have to do that.  If you ever hope to have to restore a new firewall, this is a much easier way to do it.  Schedule this to run via crontab as well to automate backups.
