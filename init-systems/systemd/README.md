# systemd unit for docker-volume-glusterfs
## configure your glusterfs nodes
The docker-volume-glusterfs plugin must be configured with the glusterfs nodes using a config file.
```bash
vi etc/docker-volume-glusterfs.conf
```

## copy the config and init script inside of your /etc/ folder
```bash
sudo cp ./etc/systemd/system/docker-volume-glusterfs.service /etc/systemd/system/
sudo cp ./etc/docker-volume-glusterfs.conf /etc/
sudo chown root:root /etc/systemd/system/docker-volume-glusterfs.service /etc/docker-volume-glusterfs.conf
sudo chmod 664 /etc/systemd/system/docker-volume-glusterfs.service /etc/docker-volume-glusterfs.conf
```
## reload the systemd configuration
```bash
sudo systemctl daemon-reload
```

## enable the docker-volume-glusterfs service
```bash
sudo systemctl enable docker-volume-glusterfs
```

## start the docker-volume-glusterfs service
```bash
sudo systemctl start docker-volume-glusterfs
```

## check the logs
```bash
sudo systemctl status docker-volume-glusterfs
```
