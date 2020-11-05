# pumptrakr-tcp-server

### Proxy TCP Server For Pumptrakr Module Communication

This application is a proxy server designed for the Pumptrakr hardware modules to connect to via TCP, send messages, and forward the messages to the primary application via HTTP. The application accepts arbitrary TCP communications to port 3333, and if the message sent is not blank, it forwards that message via HTTP to the main PumpTrakr application for processing. After posting the received communication, it then disconnects from the client.

### Deployment Instructions

##### Login:
`ssh -i "path/to/admin_key.pem" ubuntu@ec2-3-128-153-169.us-east-2.compute.amazonaws.com`

##### Change directories to where the systemd script specified the WorkingGroup
 `cd /home/ubuntu/pumptrakr-tcp-server`

##### Pull down new master branch
`git pull`

##### Restart the service:
 `systemctl restart tcp_service`
