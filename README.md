# pansh


A small collection of shell scripts to use to manage Palo Alto firewalls.  Some of the initial scripts that I am publishing I think a lot of people can utilize and the coding rookies of the world, like myself, can see what's going on with it and modify it pretty simply to meet their needs.  The other coding folks will scoff and ask why I didn't use python.  See above.

Only tested using Ubuntu 18 and 20.


There are four initial scripts that you'll want to use:

paloalto-var.sh
  A collection of variables being sourced from other scripts
  
paloalto-inventory.sh
  Creates the list of 

paloalto-reboot.sh
  A reboot script, pretty dangerous.  The way I set up my box 
  I have the following in crontab:
  00 03 * * * /home/path-to/scripts/paloalto-reboot.sh
  This will check to see if there are any firewalls in the rebootlist.txt and if so, then at the scheduled time (in my case, 0300 / 3:00AM) it will reboot firewalls.
  It sleeps for :30 min and then checks to see if the firewall is operational or not, and then will email you.  You may have to setup sendmail on your box to get email notifications.
  
  
