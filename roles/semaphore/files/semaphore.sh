wget -O database.boltdb  https://hub.gitmirror.com/https://github.com/v2vv/ansible/blob/main/roles/semaphore/files/database.boltdb
wget -O config.json https://hub.gitmirror.com/https://github.com/v2vv/ansible/blob/main/roles/semaphore/files/config.json
wget -O docker-compose.yaml https://hub.gitmirror.com/https://github.com/v2vv/ansible/blob/main/roles/semaphore/files/docker-compose.yaml
docker compose up -d
