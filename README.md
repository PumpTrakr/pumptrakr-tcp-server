# pumptrakr-tcp-server

### Proxy TCP Server For Pumptrakr Module Communication

This application is a proxy server designed for the Pumptrakr hardware modules to connect to via TCP, send messages, and forward the messages to the primary application via HTTP. The application accepts arbitrary TCP communications to port 3333, and if the message sent is not blank, it forwards that message via HTTP to the main PumpTrakr application for processing. After posting the received communication, it then disconnects from the client.

Deployment steps:

1. Provision a droplet
2. Set passwords
3. Install Docker: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04
4. Install Image: https://www.digitalocean.com/community/questions/how-do-i-uload-my-docker-image-to-digital-ocean
5. Run Image: docker run -p 3333:3333 pumptrakr-tcp-server