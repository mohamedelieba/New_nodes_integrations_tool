#!/bin/bash
DATE=$(date +'%Y%m%d')
for i in `cat config.txt`
do
HOST=`echo $i | cut -d, -f2`

# Backup the old configuration 
ssh sdpuser@${HOST} cp -p  /var/opt/fds/config/Diameter/DiameterStack.cfg /var/opt/fds/config/Diameter/DiameterStack_bk_${DATE} 

# Add the Header to the output file 
echo '<?xml version='1.0' encoding='ISO-8859-1' standalone='no'?>
<Request Operation="SetRoutes" SessionId="19jreZQ5" Origin="GUI" MO="DiameterStack">' >> file.txt
ssh  -n sdpuser@${HOST} more /var/opt/fds/config/Diameter/DiameterStack.cfg | sed -n '/<DiameterStackConfig Name=\"DCIP\/Member2\">/,/<\/DiameterStackConfig>/p' | egrep "<Route|<DiameterStackConfig" >> file.txt

# Take the new Peers from User Input
until [ "$REPLY" = "exit" ]
do
read -p "enter your new host: " HOSTNAME
read -p "enter your new realm: " REALM

# Define New Peers
if [ ! -z $HOSTNAME -a ! -z $REALM ]
then
echo "<Route Peers=${HOSTNAME} Realm=${REALM} VendorId=\"193\" ApplicationId=\"16777301\"></Route>"  >> file.txt
fi
read -p "Press ENTER to define a new route and type exit if you want to END: "
done

# Add teh End tag
echo '</Routes>
</DiameterStackConfig>
</Request>' >> file.txt

# Copy the aggregated file All Nodes
scp file.txt  sdpuser@${HOST}:SDP_Req_Senders/file.txt

# Use the aggregated file to define new peers on all Nodes
ssh sdpuser@${HOST} "cd SDP_Req_Senders/ ; FDSRequestSender -u ${USERNAME} -p ${PASSWORD} file.txt > out.xml"
done
