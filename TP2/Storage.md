# IV. Blob Storage

⚠️⚠️⚠️ **Dans cette partie, on bosse que avec `azure2.tp2`**

## 1. Un premier ptit blobz

➜ **Créer un *Storage Account***

```powershell
PS C:\Users\emrep> az storage account create -n step24 -g TT -l spaincentral --sku Standard_LRS --kind StorageV2 -o table
AccessTier    AllowBlobPublicAccess    AllowCrossTenantReplication    CreationTime                      EnableHttpsTrafficOnly    Kind       Location      MinimumTlsVersion    Name    PrimaryLocation    ProvisioningState    ResourceGroup    StatusOfPrimary
------------  -----------------------  -----------------------------  --------------------------------  ------------------------  ---------  ------------  -------------------  ------  -----------------  -------------------  ---------------  -----------------
Hot           False                    False                          2025-11-02T09:35:16.540087+00:00  True                      StorageV2  spaincentral  TLS1_0               step24  spaincentral       Succeeded            TT               available
```

➜ **Créer un *Blob Container***

```
PS C:\Users\emrep> az storage container create --account-name step24 --name meow --auth-mode login -o table
Created
---------
True
```

➜ **Activer la "*Managed Identity*" pour votre VM `azure2.tp2`**
➜ **Donner le rôle "Storage Blob Contributor" à `azure2.tp2`**

```powershell
PS C:\Users\emrep> $principalId = az vm identity assign -g TT -n azure2.tp1 --query principalId -o tsv
PS C:\Users\emrep> $saId = az storage account show -n step24 -g TT --query id -o tsv
PS C:\Users\emrep> az role assignment create `
>>   --assignee-object-id $principalId `
>>   --assignee-principal-type ServicePrincipal `
>>   --role "Storage Blob Data Contributor" `
>>   --scope $saId -o table
CreatedOn                         Name                                  PrincipalId                           PrincipalType     ResourceGroup    RoleDefinitionId                                                                                                                            Scope                                                                                                                     UpdatedBy                             UpdatedOn
--------------------------------  ------------------------------------  ------------------------------------  ----------------  ---------------  ------------------------------------------------------------------------------------------------------------------------------------------  ------------------------------------------------------------------------------------------------------------------------  ------------------------------------  --------------------------------
2025-11-02T09:45:25.128965+00:00  c0ee9862-5419-45eb-95e8-104f18a54df0  eb0f163b-7345-43f0-8b95-e542ffa77c3f  ServicePrincipal  TT               /subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe  /subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/resourceGroups/TT/providers/Microsoft.Storage/storageAccounts/step24  0518a76d-9c75-48bc-aa87-5fb95db5689c  2025-11-02T09:45:25.464978+00:00
```

🌞 **Upload un fichier dans le *Blob Container* depuis `azure2.tp2`**

```bash
azureuser@azure2:~$ az login --identity
***************
azureuser@azure2:~$ echo "meow" > /tmp/meow.txt
azureuser@azure2:~$ az storage blob upload --account-name step24 --container-name meow --name meow.txt --file /tmp/meow.txt --auth-mode login -o table
Finished[#############################################################]  100.0000%
Client_request_id                     Content_md5               Date                       LastModified               Request_id                            Request_server_encrypted    Version
------------------------------------  ------------------------  -------------------------  -------------------------  ------------------------------------  --------------------------  ----------
81095569-b7d1-11f0-b9da-7ced8d6465b0  rWBtaiSi3smCvCmTqq+RYA==  2025-11-02T09:51:29+00:00  2025-11-02T09:51:30+00:00  5af73abe-601e-0004-1dde-4ba41a000000  True                        2022-11-02
```

🌞 **Download un fichier du *Blob Container***

```powershell
PS C:\Users\emrep> $container="meow"; $name="meow.txt"
PS C:\Users\emrep> $dest = Join-Path $env:TEMP $name
PS C:\Users\emrep> az storage blob download --account-name $sa --container-name $container --name $name --file $dest --auth-mode login -o table
Finished[#############################################################]  100.0000%
Name      Blob Type    Blob Tier    Length    Content Type    Last Modified              Snapshot
--------  -----------  -----------  --------  --------------  -------------------------  ----------
meow.txt  BlockBlob                 5         text/plain      2025-11-02T09:51:30+00:00
PS C:\Users\emrep> Get-Content $dest
meow
```

## 2. Haïssez-moi

### B. Utilisateur MySQL

🌞 **Créer un ptit user SQL pour notre script**

```bash
azureuser@azure2:~$ sudo mysql <<'SQL'
CREATE USER 'backup'@'localhost' IDENTIFIED BY '*****';
GRANT SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES ON meow_database.* TO 'backup'@'localhost';
FLUSH PRIVILEGES;
SQL
```

🌞 **Tester que vous pouvez vous connecter avec cet utilisateur**

- depuis la VM toujours : `mysql -u backup -h localhost -p`

```bash
azureuser@azure2:~$ mysql -u backup -h 127.0.0.1 -p'*******' -e "SHOW DATABASES LIKE 'meow_database';"
+--------------------------+
| Database (meow_database) |
+--------------------------+
| meow_database            |
+--------------------------+
```

### C. Script `db_backup.sh`

🌞 **Ecrire le script `db_backup.sh`**

- il utilise une commande `mysqldump` pour récupérer le contenu de la base de données
- une commande `tar` pour archiver et compresser en `.tar.gz`
- une commande `az` pour uploader la backup sur notre ptit *Blob Container*
- un clean : le fichier `.tar.gz` doit être supprimé de la machine

🌞 **Environnement du script `db_backup.sh`**

```bash
azureuser@azure2:~$ sudo useradd -r -s /usr/sbin/nologin -d /var/lib/backup backup 2>/dev/null || true
azureuser@azure2:~$ sudo install -d -o backup -g backup /var/lib/backup /var/lib/backup/.azure
azureuser@azure2:~$ sudo tee /usr/local/bin/db_backup.sh >/dev/null <<'EOF'
azureuser@azure2:~$ sudo chown backup:backup /usr/local/bin/db_backup.sh
azureuser@azure2:~$ sudo chmod 700 /usr/local/bin/db_backup.sh
```

🌞 **Récupérer le blob**

```powershell
PS C:\Users\emrep> $sa="step24"; $container="meow"; $name="meow.txt"
PS C:\Users\emrep> $dest = Join-Path $env:TEMP $name
PS C:\Users\emrep> az storage blob download --account-name $sa --container-name $container --name $name --file $dest --auth-mode login -o table
Finished[#############################################################]  100.0000%
Name      Blob Type    Blob Tier    Length    Content Type    Last Modified              Snapshot
--------  -----------  -----------  --------  --------------  -------------------------  ----------
meow.txt  BlockBlob                 5         text/plain      2025-11-02T09:51:30+00:00
PS C:\Users\emrep> Get-Content $dest
meow
```

📁 **Dans le dépôt git : votre `db_backup.sh`**

### D. Service

🌞 **Ecrire un fichier `/etc/systemd/system/db_backup.service`**

- il doit lancer le script `/usr/local/bin/db_backup.sh`
- en tant que l'utilisateur `backup`
- il faudra indiquer `Type=oneshot` dans la section `[Service]`

    - par défaut, un service, c'est un truc qui tourne en permanence
    - donc un script de backup qui s'exécute puis se termine, ça affichera le service en `Failed` une fois terminé
    - on indique explicitement avec `Type=oneshot` que c'est un programme qui va se terminer et c'est normal

📁 **Dans le dépôt git : votre `db_backup.service`**

---

🌞 **Tester**

```bash
azureuser@azure2:~$ sudo systemctl start db_backup.service
azureuser@azure2:~$ systemctl status db_backup.service --no-pager -l
○ db_backup.service - DB backup to Blob Storage
     Loaded: loaded (/etc/systemd/system/db_backup.service; disabled; preset: enabled)
     Active: inactive (dead)

Nov 02 10:34:49 azure2 systemd[1]: Finished db_backup.service - DB backup to Blob Storage.
Nov 02 10:34:49 azure2 systemd[1]: db_backup.service: Consumed 1.234s CPU time.
Nov 02 10:37:27 azure2 systemd[1]: Starting db_backup.service - DB backup to Blob Storage...
Nov 02 10:37:29 azure2 db_backup.sh[3867]: [166B blob data]
Nov 02 10:37:29 azure2 db_backup.sh[3867]: Client_request_id                     Content_md5               Date                       LastModified               Request_id                            Request_server_encrypted    Version
Nov 02 10:37:29 azure2 db_backup.sh[3867]: ------------------------------------  ------------------------  -------------------------  -------------------------  ------------------------------------  --------------------------  ----------
Nov 02 10:37:29 azure2 db_backup.sh[3867]: edfa2e63-b7d7-11f0-b9da-7ced8d6465b0  gCaZb/A6LiFEhHpljY1dPg==  2025-11-02T10:37:28+00:00  2025-11-02T10:37:29+00:00  dde45ad2-001e-002d-66e4-4b9a6e000000  True                        2022-11-02
Nov 02 10:37:29 azure2 systemd[1]: db_backup.service: Deactivated successfully.
Nov 02 10:37:29 azure2 systemd[1]: Finished db_backup.service - DB backup to Blob Storage.
Nov 02 10:37:29 azure2 systemd[1]: db_backup.service: Consumed 1.228s CPU time.
```

### E. Timer

🌞 **Ecrire un fichier `/etc/systemd/system/db_backup.timer`**

```ini
[Unit]
Description=Sauvegarde de la DB toutes les 1 min

[Timer]
# Premier lancement 1 minutes après le boot
OnBootSec=1min

# Et ensuite, ça retrigger 1 minutes après que ça soit stopped
OnUnitActiveSec=1min
Unit=db_backup.service

[Install]
WantedBy=timers.target
```

🌞 **Activer le Timer**

- avec un `sudo systemctl start db_backup.timer`
- activation au boot `sudo systemctl enable db_backup.timer`

```bash
azureuser@azure2:~$ sudo systemctl start db_backup.timer
azureuser@azure2:~$ sudo systemctl enable db_backup.timer
Created symlink /etc/systemd/system/timers.target.wants/db_backup.timer → /etc/systemd/system/db_backup.timer.
```

🌞 **Attendre et observer**

- `sudo systemctl list-timers` pour voir la prochaine exécution
- prouver que ça trigger bien votre service et donc votre script et donc un upload sur *Blob Storage*

```bash
azureuser@azure2:~$ sudo systemctl list-timers
NEXT                            LEFT LAST                              PASSED UNIT                           ACTIVATES          >
Sun 2025-11-02 10:41:37 UTC      10s Sun 2025-11-02 10:40:37 UTC      49s ago db_backup.timer                db_backup.service
Sun 2025-11-02 10:50:00 UTC     8min Sun 2025-11-02 10:40:07 UTC 1min 20s ago sysstat-collect.timer          sysstat-collect.ser>
Sun 2025-11-02 11:16:53 UTC    35min Sun 2025-11-02 10:22:38 UTC    18min ago fwupd-refresh.timer            fwupd-refresh.servi>
Sun 2025-11-02 19:52:41 UTC       9h Sun 2025-11-02 10:40:42 UTC      44s ago motd-news.timer                motd-news.service
Mon 2025-11-03 00:00:00 UTC      13h Sun 2025-11-02 09:24:41 UTC 1h 16min ago dpkg-db-backup.timer           dpkg-db-backup.serv>
Mon 2025-11-03 00:00:00 UTC      13h Sun 2025-11-02 09:24:41 UTC 1h 16min ago logrotate.timer                logrotate.service
Mon 2025-11-03 00:07:00 UTC      13h -                                      - sysstat-summary.timer          sysstat-summary.ser>
Mon 2025-11-03 00:56:28 UTC      14h Wed 2025-10-29 18:04:45 UTC            - fstrim.timer                   fstrim.service
Mon 2025-11-03 04:29:29 UTC      17h Sun 2025-11-02 10:40:42 UTC      44s ago apt-daily.timer                apt-daily.service
Mon 2025-11-03 06:57:21 UTC      20h Sun 2025-11-02 10:18:05 UTC    23min ago apt-daily-upgrade.timer        apt-daily-upgrade.s>
Mon 2025-11-03 09:29:45 UTC      22h Sun 2025-11-02 09:29:45 UTC 1h 11min ago update-notifier-download.timer update-notifier-dow>
Mon 2025-11-03 09:39:37 UTC      22h Sun 2025-11-02 09:39:37 UTC  1h 1min ago systemd-tmpfiles-clean.timer   systemd-tmpfiles-cl>
Mon 2025-11-03 11:21:57 UTC      24h Sun 2025-11-02 09:27:38 UTC 1h 13min ago man-db.timer                   man-db.service
Mon 2025-11-03 13:46:03 UTC 1 day 3h Wed 2025-10-29 18:04:45 UTC            - update-notifier-motd.timer     update-notifier-mot>
Sun 2025-11-09 03:10:18 UTC   6 days Sun 2025-11-02 09:25:38 UTC 1h 15min ago e2scrub_all.timer              e2scrub_all.service
```

```bash
azureuser@azure2:~$ az storage blob list \
  --account-name step24 \
  --container-name meow \
  --prefix backups/ \
  --auth-mode login -o table
Name                                           Blob Type    Blob Tier    Length    Content Type     Last Modified              Snapshot
---------------------------------------------  -----------  -----------  --------  ---------------  -------------------------  ----------
backups/meow_database_20251102T103422Z.sql.gz  BlockBlob    Hot          804       application/sql  2025-11-02T10:34:28+00:00
backups/meow_database_20251102T103448Z.sql.gz  BlockBlob    Hot          804       application/sql  2025-11-02T10:34:49+00:00
backups/meow_database_20251102T103727Z.sql.gz  BlockBlob    Hot          804       application/sql  2025-11-02T10:37:29+00:00
backups/meow_database_20251102T104037Z.sql.gz  BlockBlob    Hot          803       application/sql  2025-11-02T10:40:39+00:00
backups/meow_database_20251102T104207Z.sql.gz  BlockBlob    Hot          803       application/sql  2025-11-02T10:42:08+00:00
backups/meow_database_20251102T104312Z.sql.gz  BlockBlob    Hot          804       application/sql  2025-11-02T10:43:13+00:00
```