#!/bin/bash

inotifywait -m /etc/nginx/sites-available -e create | while read path action file; 
do
  NEWFILE=$file

  # Check if the NGINX configuration is correct
  nginx -t
  if [ $? -eq 0 ]; then
     echo "New configuration file has been created: $NEWFILE"
     echo
     ln -s /etc/nginx/sites-available/$NEWFILE /etc/nginx/sites-enabled/
     echo "Symbolic link in sites-enabled directory has been created"
     echo 

     # Extract the domain from the new file created
     domain=$(awk '/server_name/ {print $2}' /etc/nginx/sites-available/$NEWFILE | sed 's/;//')
     if [ -n "$domain" ]; then     
        # Issue SSL certificate with acme.sh
        acme.sh --issue -d $domain --nginx --reloadcmd "systemctl reload nginx"
        if [ $? -eq 0 ]; then     
           # Create renewal script
           echo "echo 'Renewing SSL certificates' && acme.sh --renew -d $domain --nginx --reloadcmd 'systemctl reload nginx'" > /home/cert-scripts/"$domain"-renew.sh
           chmod u+x /home/cert-scripts/"$domain"-renew.sh

           # Update crontab for automatic renewal
           crontab -l > temp_cron
           echo "0 9 1 * * /home/cert-scripts/$domain-renew.sh" >> temp_cron
           crontab temp_cron
           rm -f temp_cron
           echo "A new crontab entry has been created for the domain $domain."
        else
           echo "There was an error obtaining the SSL certificate"
           exit 1
        fi
     else
       echo "No domain was found in $NEWFILE"
     fi
  else
     echo "There is an error in the nginx configuration files"
  fi
done