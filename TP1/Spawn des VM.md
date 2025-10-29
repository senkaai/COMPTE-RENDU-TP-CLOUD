# II. Spawn des VMs

## 1. Depuis la WebUI

🌞 **Connectez-vous en SSH à la VM pour preuve**

```
PS C:\Users\emrep\.ssh> ssh VM1
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.14.0-1012-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Oct 29 10:34:47 UTC 2025

  System load:  0.01              Processes:             113
  Usage of /:   5.7% of 28.02GB   Users logged in:       0
  Memory usage: 29%               IPv4 address for eth0: 172.17.0.4
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update

Last login: Wed Oct 29 10:33:15 2025 from 185.100.234.208
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

redz@VM1:~$
```

## 2. `az` : a programmatic approach

🌞 **Créez une VM depuis le Azure CLI** : `azure1.tp1`

- en utilisant uniquement la commande `az` donc
- je vous laisse faire vos recherches pour créer une VM avec la commande `az`
- vous devrez préciser :

    - quel **utilisateur** doit être créé à la création de la VM
    - le **fichier de clé utilisé** pour se connecter à cet utilisateur
    - comme ça, **dès que la VM pop, on peut se co en SSH !**
```
PS C:\Users\emrep> az group create --name TT --location spaincentral
{
  "id": "/subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/resourceGroups/TT",
  "location": "spaincentral",
  "managedBy": null,
  "name": "TT",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
```

```
PS C:\Users\emrep> az vm create `
>> --resource-group TT `
>> --name azure1.tp1 `
>> --image Ubuntu2404 `
>> --size Standard_B1s `
>> --admin-username azureuser `
>> --ssh-key-values "C:\Users\emrep\.ssh\cloud_tp.pub" `
>> --public-ip-sku Standard `
>> --location spaincentral
The default value of '--size' will be changed to 'Standard_D2s_v5' from 'Standard_DS1_v2' in a future release.
{
  "fqdns": "",
  "id": "/subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/resourceGroups/TT/providers/Microsoft.Compute/virtualMachines/azure1.tp1",
  "location": "spaincentral",
  "macAddress": "7C-ED-8D-64-17-BF",
  "powerState": "VM running",
  "privateIpAddress": "10.0.0.4",
  "publicIpAddress": "158.158.48.205",
  "resourceGroup": "TT"
}
```

🌞 **Assurez-vous que vous pouvez vous connecter à la VM en SSH sur son IP publique**

- une commande SSH fonctionnelle vers la VM sans password toujouuurs because Agent SSH
```
azureuser@azure1:~$ ssh azureuser@158.158.48.205
The authenticity of host '158.158.48.205 (158.158.48.205)' can't be established.
ED25519 key fingerprint is SHA256:6mOOlyXiBrcVlhljUQpnAxUJOfFvulpWijB1FFRHT+E.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '158.158.48.205' (ED25519) to the list of known hosts.
azureuser@158.158.48.205: Permission denied (publickey).
azureuser@azure1:~$ exit
logout
Connection to 158.158.48.205 closed.
PS C:\Users\emrep> ssh azureuser@158.158.48.205
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.14.0-1012-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Oct 29 18:15:41 UTC 2025

  System load:  0.0               Processes:             117
  Usage of /:   5.7% of 28.02GB   Users logged in:       1
  Memory usage: 31%               IPv4 address for eth0: 10.0.0.4
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update

Last login: Wed Oct 29 18:12:14 2025 from 37.174.4.42
azureuser@azure1:~$
```

🌞 **Une fois connecté, prouvez la présence...**

- **...du service `walinuxagent.service`**
```
azureuser@azure1:~$ sudo systemctl status walinuxagent.service
● walinuxagent.service - Azure Linux Agent
     Loaded: loaded (/usr/lib/systemd/system/walinuxagent.service; enabled; preset: enabled)
    Drop-In: /run/systemd/system.control/walinuxagent.service.d
             └─50-CPUAccounting.conf, 50-MemoryAccounting.conf
     Active: active (running) since Wed 2025-10-29 18:02:08 UTC; 12min ago
   Main PID: 1062 (python3)
      Tasks: 7 (limit: 993)
     Memory: 53.2M (peak: 55.3M)
        CPU: 2.643s
     CGroup: /azure.slice/walinuxagent.service
             ├─1062 /usr/bin/python3 -u /usr/sbin/waagent -daemon
             └─1553 /usr/bin/python3 -u bin/WALinuxAgent-2.14.0.1-py3.12.egg -run-exthandlers
```

- **...du service `cloud-init.service`**
```
azureuser@azure1:~$ sudo systemctl status cloud-init.service
● cloud-init.service - Cloud-init: Network Stage
     Loaded: loaded (/usr/lib/systemd/system/cloud-init.service; enabled; preset: enabled)
     Active: active (exited) since Wed 2025-10-29 18:02:06 UTC; 12min ago
   Main PID: 735 (code=exited, status=0/SUCCESS)
        CPU: 861ms

Oct 29 18:02:06 azure1 cloud-init[740]: |    o*=o . +     |
Oct 29 18:02:06 azure1 cloud-init[740]: |    .o+=    E    |
Oct 29 18:02:06 azure1 cloud-init[740]: |   . .=.         |
Oct 29 18:02:06 azure1 cloud-init[740]: |  o  . .S        |
Oct 29 18:02:06 azure1 cloud-init[740]: |  .oo.o*.        |
Oct 29 18:02:06 azure1 cloud-init[740]: |   +.+*+         |
Oct 29 18:02:06 azure1 cloud-init[740]: |    +==.         |
Oct 29 18:02:06 azure1 cloud-init[740]: |   .o=+.         |
Oct 29 18:02:06 azure1 cloud-init[740]: +----[SHA256]-----+
Oct 29 18:02:06 azure1 systemd[1]: Finished cloud-init.service - Cloud-init: Network Stage.
```
## 3. Spawn moar moar moaaar VMs

### A. Another VM another friend :d

🌞 **Créez une deuxième VM** : `azure2.tp1`

- avec une commande `az`
- elle ne doit **PAS** avoir d'adresse IP publique

```
PS C:\Users\emrep> az vm create `
>> --resource-group TT `
>> --name azure2.tp1 `
>> --public-ip-address '""'`
>> --image Ubuntu2404 `
>> --size Standard_B1s `
>> --admin-username azureuser `
>> --ssh-key-values "C:\Users\emrep\.ssh\cloud_tp.pub" `
>> --public-ip-sku Standard `
>> --location spaincentral
The default value of '--size' will be changed to 'Standard_D2s_v5' from 'Standard_DS1_v2' in a future release.
{
  "fqdns": "",
  "id": "/subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/resourceGroups/TT/providers/Microsoft.Compute/virtualMachines/azure2.tp1",
  "location": "spaincentral",
  "macAddress": "7C-ED-8D-64-65-B0",
  "powerState": "VM running",
  "privateIpAddress": "10.0.0.5",
  "publicIpAddress": "",
  "resourceGroup": "TT"
}
```

🌞 **Affichez des infos au sujet de vos deux VMs**

- avec une/des commande(s) `az`
- on doit voir :

    - que `azure1.tp1` a une adresse IP publique et une adresse IP privée
    - que `azure2.tp1` n'a PAS d'adresse IP publique mais a une adresse IP privée
```
PS C:\Users\emrep> az vm show -g TT -n azure1.tp1 -d --query "{name:name,publicIP:publicIps,privateIP:privateIps}"
{
  "name": "azure1.tp1",
  "privateIP": "10.0.0.4",
  "publicIP": "158.158.48.205"
}
```

```
PS C:\Users\emrep> az vm show -g TT -n azure2.tp1 -d --query "{name:name,publicIP:publicIps,privateIP:privateIps}"
{
  "name": "azure2.tp1",
  "privateIP": "10.0.0.5",
  "publicIP": ""
}
```

### B. Config SSH client

🌞 **Configuration SSH client pour les deux machines**

- vous **devez** rebondir sur `azure1.tp1` (car c'est la seule exposée sur internet) pour accéder à `azure2.tp1`
- vous **devez** utiliser un fichier `config` SSH client, pour que ces deux commandes fonctionnent juste :

```bash
PS C:\Users\emrep> ssh -A az1
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.14.0-1012-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Oct 29 18:11:56 UTC 2025

  System load:  0.0               Processes:             117
  Usage of /:   5.7% of 28.02GB   Users logged in:       1
  Memory usage: 32%               IPv4 address for eth0: 10.0.0.4
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update

Last login: Wed Oct 29 18:11:57 2025 from 37.174.4.42
azureuser@azure1:~$ ssh az2
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.14.0-1012-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Oct 29 18:12:19 UTC 2025

  System load:  0.11              Processes:             116
  Usage of /:   5.7% of 28.02GB   Users logged in:       1
  Memory usage: 32%               IPv4 address for eth0: 10.0.0.5
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update

Last login: Wed Oct 29 18:08:32 2025 from 10.0.0.4
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

azureuser@azure2:~$
```

- 📁 **dans le compte-rendu, livez-moi juste votre fichier `config` et les deux commandes SSH fonctionnelles**

