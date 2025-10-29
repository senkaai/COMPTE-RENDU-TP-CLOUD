# III. Déployer et configurer un machin

## 1. Machine `azure2.tp1`

🌞 **Installer MySQL/MariaDB sur `azure2.tp1`**

```
sudo apt update
sudo apt install -y mariadb-server ufw
```

🌞 **Démarrer le service MySQL/MariaDB sur `azure2.tp1`**

```
azureuser@azure2:~$ sudo systemctl enable --now mariadb
Synchronizing state of mariadb.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable mariadb
```

🌞 **Ajouter un utilisateur dans la base de données pour que mon app puisse s'y connecter**

- connectez-vous à la base de données pour pouvoir l'administrer en SQL
- caractéristiques attendus de l'utilisateur :

    - appelez l'utilisateur `meow`
    - le password doit être `meow`
    - il doit être autorisé à se connecter depuis n'importe quelle machine
    - il doit avoir tous les droits sur la database `meow_database`

```bash
azureuser@azure2:~$ sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`meow_database\`;"
azureuser@azure2:~$ sudo mysql -e "CREATE USER IF NOT EXISTS 'meow'@'%' IDENTIFIED BY 'meow';"
azureuser@azure2:~$ sudo mysql -e "GRANT ALL PRIVILEGES ON \`meow_database\`.* TO 'meow'@'%';"
azureuser@azure2:~$ sudo mysql -e "FLUSH PRIVILEGES;"
```

    ```SQL
    CREATE DATABASE meow_database;
    CREATE USER 'meow'@'%' IDENTIFIED BY 'meow';
    GRANT ALL ON meow_database.* TO 'meow'@'%';
    FLUSH PRIVILEGES;
    ```

🌞 **Ouvrez un port firewall si nécessaire**

```bash
azureuser@azure2:~$ sudo ss -lnpt | grep 3306 || true
LISTEN 0      80         127.0.0.1:3306      0.0.0.0:*    users:(("mariadbd",pid=3122,fd=21))
azureuser@azure2:~$ sudo ufw --force enable
Firewall is active and enabled on system startup
azureuser@azure2:~$ sudo ufw allow from 10.0.0.4 to any port 3306 proto tcp
Rule added
azureuser@azure2:~$ sudo ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
3306/tcp                   ALLOW IN    10.0.0.4
azureuser@azure2:~$ sudo ss -lnpt | grep 3306 || true
LISTEN 0      80         127.0.0.1:3306      0.0.0.0:*    users:(("mariadbd",pid=3122,fd=21))
```

## 2. Machine `azure1.tp1`

**Ici on va déployer le site web.**

Au menuuu :

1. récupération de l'application sur la machine
2. installation des dépendances de l'application
3. configuration de l'application
4. gestion de users et de droits
5. création d'un service `webapp.service` pour lancer l'application
6. ouverture du port dans le firewall si nécessaire
7. lancement du service

**Let's goooo 🔥🔥**

---

### A. Récupération de l'application sur la machine

🌞 **Récupération de l'application sur la machine**

```bash
azureuser@azure1:~$ git clone https://gitlab.com/it4lik/b2-pano-cloud-2025.git /tmp/repo
Cloning into '/tmp/repo'...
remote: Enumerating objects: 297, done.
remote: Counting objects: 100% (217/217), done.
remote: Compressing objects: 100% (214/214), done.
remote: Total 297 (delta 96), reused 0 (delta 0), pack-reused 80 (from 1)
Receiving objects: 100% (297/297), 7.92 MiB | 19.55 MiB/s, done.
Resolving deltas: 100% (119/119), done.
```
```bash
azureuser@azure1:/opt/meow$ ls -la /opt/meow
total 20
drwxr-xr-x 3 azureuser azureuser 4096 Oct 29 18:30 .
drwxr-xr-x 3 root      root      4096 Oct 29 18:28 ..
-rw-rw-r-- 1 azureuser azureuser 3827 Oct 29 18:30 app.py
-rw-rw-r-- 1 azureuser azureuser   58 Oct 29 18:30 requirements.txt
drwxrwxr-x 2 azureuser azureuser 4096 Oct 29 18:30 templates
```

### B. Installation des dépendances de l'application

🌞 **Installation des dépendances de l'application**

- déplacez-vous dans le dossier de l'application
- exécutez les commandes suivantes :

```bash
# Assurez vous d'être dans le dossier où se trouve l'application
cd /opt/meow

# Création d'un environnement virtuel (on pourrit pas l'install Python de la machine hôte)
python -m venv .
azureuser@azure1:/opt/meow$ /opt/meow/venv/bin/pip install -r /opt/meow/requirements.txt

# Installation des dépendances de l'application
./bin/pip install -r requirements.txt
azureuser@azure1:/opt/meow$ /opt/meow/venv/bin/pip install -r /opt/meow/requirements.txt
```

---

### C. Configuration de l'application

🌞 **Configuration de l'application**

- modifier le fichier `/opt/meow/.env`
- modifier uniquement **la valeur de `DB_HOST`** pour indiquer l'adresse IP de `azure2.tp1`

```bash
azureuser@azure1:/opt/meow$ sudo nano /opt/meow/.env

  GNU nano 7.2                                                   /opt/meow/.env
DB_HOST=10.0.0.5
DB_USER=meow
DB_PASSWORD=meow
DB_NAME=meow_database
DB_PORT=3306
FLASK_HOST=0.0.0.0
FLASK_PORT=8000
FLASK_DEBUG=False
```

### D. Gestion de users et de droits

🌞 **Gestion de users et de droits**

- **créez un utilisateur `webapp`** (commande `useradd`)
- **le dossier `/opt/meow` et tout son contenu doivent appartenir** (commande `chown`) : 

    - au user `webapp`
    - au groupe `webapp`

- **les "autres" ne doivent avoir aucun droit sur ce dossier** et son contenu (commande `chmod`)

```bash
azureuser@azure1:/opt/meow$ ls -ld /opt/meow
drwx------ 4 webapp webapp 4096 Oct 29 18:40 /opt/meow
azureuser@azure1:/opt/meow$ ls -l /opt/meow | sed -n '1,200p'
ls: cannot open directory '/opt/meow': Permission denied
```

### E. Création d'un service `webapp.service` pour lancer l'application

🌞 **Création d'un service `webapp.service` pour lancer l'application**

- **créez le fichier `/etc/systemd/system/webapp.service`**

```ini
azureuser@azure1:/opt/meow$ sudo nano /etc/systemd/system/webapp.service

  GNU nano 7.2                               /etc/systemd/system/webapp.service *
[Unit]
Description=Super Webapp MEOW
After=network.target

[Service]
User=webapp
Group=webapp
WorkingDirectory=/opt/meow
EnvironmentFile=/opt/meow/.env
ExecStart=/opt/meow/venv/bin/python /opt/meow/app.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

- **exécutez ensuite un `sudo systemctl daemon-reload`** pour indiquer au système qu'on a modifié les services

### F. Ouverture du port dans le(s) firewall(s)

🌞 **Ouverture du port80 dans le(s) firewall(s)**
```bash
azureuser@azure1:/opt/meow$ sudo ufw --force enable
Firewall is active and enabled on system startup
azureuser@azure1:/opt/meow$ sudo ufw allow 80/tcp
Rule added
Rule added (v6)
azureuser@azure1:/opt/meow$ sudo ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
80/tcp                     ALLOW IN    Anywhere
80/tcp (v6)                ALLOW IN    Anywhere (v6)
```

- suivant l'OS que vous avez choisi, la commande pourra changer pour ouvrir le port, je vous laisse chercher

    - probablement une commande `ufw` sur Ubuntu
    - probablement une commande `firewall-cmd` sur Rocky
    - etc.

- **n'oubliez pas d'ouvrir aussi le port dans le firewall Azure**

    - faites-le depuis la WebUI

## 3. Visitez l'application

🌞 **L'application devrait être fonctionnelle sans soucis à partir de là**

```bash
azureuser@azure1:~$ curl -I http://158.158.48.205:8000
HTTP/1.1 200 OK
Server: Werkzeug/3.1.3 Python/3.12.3
Date: Wed, 29 Oct 2025 19:27:57 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 12566
Connection: close
```
