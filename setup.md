# NimForum setup

This document describes the steps needed to setup a working nimforum-re instance on a Linux machine.

## Requirements

* Any up-to-date or modern Linux distro
* Some Linux knowledge

## Installation

Begin by downloading the latest nimforum-re release from [here](https://github.com/penguinite/nimforum-re/releases)

Extract the downloaded tarball on your server.
These steps can be done using the following commands:

```
wget https://github.com/penguinite/nimforum-re/releases/download/latest/nimforum-re_linux_amd64.zip
unzip nimforum-re_linux_amd64.zip
```

Then ``cd`` into the forum's directory:

```
cd nimforum-re
```

### Dependencies

The following may need to be installed on your server:

```
sudo apt install libsass-dev sqlite3
```

## Configuration and DB creation

nimforum-re releases come with a hand `nimforumctl` program, which is useful for general server maintenance.
In our case, we will be using it to start the setup process.

```
./nimforumctl setup
```

And now, nimforumctl will ask you multiple questions to help you setup the server.
it will create a database setup and a config file for you, and if you are unsure of what to pick, then don't worry!
Most of the values can be changed later (either via the config file or the database)

This program will create a `nimforum-re.db` file, this contains your forum's database.
It will also create a `forum.ini` file,
you can modify this file after running the `nimforumctl` script if you've made any mistakes or just want to change things.

## Running the forum

Executing the forum is simple, just run the ``nimforum`` binary:

```
./nimforum
```

The forum will start listening to HTTP requests on port 5000
(by default, this can be changed in ``forum.ini``).

On your server you should set up a separate HTTP server.
The recommended choice is nginx.
You can then use it as a reverse proxy for NimForum.

### HTTP server

#### nginx

You can use the following nginx configuration:

```
server {
        server_name forum.hostname.com;
        autoindex off;

        location / {
                proxy_pass http://localhost:5000;
                proxy_set_header Host $host;
                proxy_set_header X-Real_IP $remote_addr;
        }
}
```

Be sure to replace ``forum.hostname.com`` with your forum's hostname.

### Supervisor

Supervisors can start up nimforum when the server boots, which means that if you configure your service manager right then nimforum can be automatically started whenever the system reboots or shuts down.

#### systemd

Create a new file called ``nimforum.service`` inside ``/lib/systemd/system/nimforum.service``.

Place the following inside it:

```
[Unit]
Description=nimforum
After=network.target httpd.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/home/<user>/nimforum-re/ # MODIFY THIS
ExecStart=/usr/bin/stdbuf -oL /home/<user>/nimforum-re/nimforum # MODIFY THIS
# Restart when crashes.
Restart=always
RestartSec=1

User=dom

StandardOutput=syslog+console
StandardError=syslog+console

[Install]
WantedBy=multi-user.target
```

**Be sure to specify the correct ``WorkingDirectory`` and ``ExecStart``!**

You can then enable and start the service by running the following:

```
sudo systemctl enable nimforum
sudo systemctl start nimforum
```

To check that everything is in order, run this:

```
systemctl status nimforum
```

You should see something like this:

```
● nimforum.service - nimforum
   Loaded: loaded (/lib/systemd/system/nimforum.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2018-05-25 22:09:59 UTC; 1 day 22h ago
 Main PID: 21474 (forum)
    Tasks: 1
   Memory: 55.2M
      CPU: 1h 15min 31.905s
   CGroup: /system.slice/nimforum.service
           └─21474 /home/dom/nimforum/src/forum
```

## Conclusion

That should be all you need to get started. Your forum should now be accessible
via your hostname, assuming that it points to your VPS' IP address.