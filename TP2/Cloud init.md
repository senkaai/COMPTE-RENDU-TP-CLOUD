# II. cloud-init

## 2. Gooooo

➜ **Sur votre PC, créez un fichier `cloud-init.txt` avec le contenu suivant :**

```yml
#cloud-config
users:
  - default
  - name: redz
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 ****************************
```


🌞 **Tester `cloud-init`**

- en créant une nouvelle VM et en lui passant ce fichier `cloud-init.txt` au démarrage
- pour ça, utilisez une commande `az vm create`
- utilisez l'option `--custom-data /path/to/cloud-init.txt`

```powershell
PS C:\Users\emrep\Documents> az vm create `
>> --resource-group TT `
>> --name VMCI `
>> --image Ubuntu2404 `
>> --size Standard_B1s `
>> --admin-username azureuser `
>> --ssh-key-values "C:\Users\emrep\.ssh\cloud_tp.pub" `
>> --public-ip-sku Standard `
>> --location spaincentral `
>> --custom-data "C:\Users\emrep\Documents\cloud-init.txt"
The default value of '--size' will be changed to 'Standard_D2s_v5' from 'Standard_DS1_v2' in a future release.
{
  "fqdns": "",
  "id": "/subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/resourceGroups/TT/providers/Microsoft.Compute/virtualMachines/VMCI",
  "location": "spaincentral",
  "macAddress": "7C-ED-8D-64-99-A8",
  "powerState": "VM running",
  "privateIpAddress": "10.0.0.6",
  "publicIpAddress": "158.158.42.5",
  "resourceGroup": "TT"
}
```

🌞 **Vérifier que `cloud-init` a bien fonctionné**

- connectez-vous en SSH à la VM nouvellement créée, directement sur le nouvel utilisateur créé par `cloud-init`
- pour debug, choper un terminal avec votre utilisateur habituel (celui indiqué avec `--admin-username`) et :

```
PS C:\Users\emrep\Documents> ssh redz@158.158.42.5
The authenticity of host '158.158.42.5 (158.158.42.5)' can't be established.
ED25519 key fingerprint is SHA256:tEdoJYk0GEloaR4DASCvls4r+UZLcUdjKeP9/+2rIXE.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '158.158.42.5' (ED25519) to the list of known hosts.
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.14.0-1012-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Thu Oct 30 09:29:48 UTC 2025

  System load:  0.17              Processes:             115
  Usage of /:   5.6% of 28.02GB   Users logged in:       0
  Memory usage: 28%               IPv4 address for eth0: 10.0.0.6
  Swap usage:   0%

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

redz@VMCI:~$
```

```bash
azureuser@VMCI:~$ whoami
azureuser
azureuser@VMCI:~$ id azureuser
uid=1001(azureuser) gid=1001(azureuser) groups=1001(azureuser),4(adm),24(cdrom),27(sudo),30(dip),105(lxd)
azureuser@VMCI:~$ id redz
uid=1000(redz) gid=1000(redz) groups=1000(redz)
azureuser@VMCI:~$ cloud-init status
status: done
azureuser@VMCI:~$ cat /home/azureuser/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIALjkmLPhOB3Ohz3poXnQCn6p/9dsPTMSmj1UhItzr62 emrep@LAPTOP-82V3F554
```

## 3. Write your own

🌞 **Utilisez `cloud-init` pour préconfigurer une VM comme `azure2.tp2` :**

- ajoutez un user qui porte votre pseudo

    - il a un password défini
    - clé SSH publique déposée
    - il a accès aux droits de `root` via `sudo`

- installer MySQL sur la machine
- déposer un fichier `init.sql` qui contient les commandes SQL du TP1
- lance une commande `mysql` pour exécuter le contenu du script `init.sql`

```yaml
#cloud-config
users:
  - default
  - name: redz
    gecos: "TP2 user"
    groups: sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
      - ssh-ed25519 ****************
ssh_pwauth: true
chpasswd:
  list: |
    redz:tp2pass
  expire: false

package_update: true
packages:
  - mariadb-server
  - ufw

write_files:
  - path: /root/init.sql
    permissions: '0644'
    content: |
      CREATE DATABASE IF NOT EXISTS `meow_database`;
      CREATE USER IF NOT EXISTS 'meow'@'%' IDENTIFIED BY 'meow';
      GRANT ALL PRIVILEGES ON `meow_database`.* TO 'meow'@'%';
      FLUSH PRIVILEGES;
  - path: /etc/mysql/mariadb.conf.d/99-bind.cnf
    permissions: '0644'
    content: |
      [mysqld]
      bind-address = 0.0.0.0

runcmd:
  - systemctl enable --now mariadb
  - mysql --protocol=socket -uroot < /root/init.sql
  - systemctl restart mariadb
  - ufw --force enable
  - ufw allow from 10.0.0.0/24 to any port 3306 proto tcp	
```

```powershell
PS C:\Users\emrep\Documents> az vm create `
>>   --resource-group TT `
>>   --name azure2.tp2 `
>>   --image Ubuntu2404 `
>>   --size Standard_B1s `
>>   --public-ip-sku Standard `
>>   --location spaincentral `
>>   --custom-data "c:\Users\emrep\Documents\cloud-init-db.yml"
The default value of '--size' will be changed to 'Standard_D2s_v5' from 'Standard_DS1_v2' in a future release.
{
  "fqdns": "",
  "id": "/subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/resourceGroups/TT/providers/Microsoft.Compute/virtualMachines/azure2.tp2",
  "location": "spaincentral",
  "macAddress": "7C-ED-8D-16-94-0F",
  "powerState": "VM running",
  "privateIpAddress": "10.0.0.6",
  "publicIpAddress": "158.158.42.211",
  "resourceGroup": "TT"
}
```

🌞 **Testez que ça fonctionne**

- un déploiement avec un `az vm create` en passant votre fichier `cloud-init.txt`
- connectez-vous en SSH, vérifiez que vous pouvez vous connecter au serveur de db (commande `mysql`) et que la base est créée

```powershell
PS C:\Users\emrep\Documents> ssh azureuser@158.158.42.211
azureuser@158.158.42.211: Permission denied (publickey).
PS C:\Users\emrep\Documents> ssh redz@158.158.42.211
redz@158.158.42.211: Permission denied (publickey).
```
(Je passe à la suite comme dit vu qu'on n'a pas trouvé de solution...)