# I. Prérequis

### A. Choix de l'algorithme de chiffrement

🌞 **Déterminer quel algorithme de chiffrement utiliser pour vos clés**

- J'ai choisi **ed25519** comme algorithme de chiffrement.

- donner un lien vers une source fiable qui explique pourquoi on évite RSA désormais (pour les connexions SSH notamment)  
  ANSSI — « L'ANSSI recommande d'éviter les algorithmes et tailles de clés considérés comme faibles et de privilégier un chiffrement modernes. »  
  Source : https://cyber.gouv.fr/sites/default/files/2014/01/NT_OpenSSH.pdf

- donner un lien vers une source fiable qui recommande un autre algorithme de chiffrement (pour les connexions SSH notamment)  
  GitHub — « La doc github recommande l'utilisation de clés SSH modernes, par exemple ed25519.»  
  Source : https://docs.github.com/fr/authentication/connecting-to-github-with-ssh/about-ssh

### B. Génération de votre paire de clés

🌞 **Générer une paire de clés pour ce TP**<>

- la clé privée doit s'appeler `cloud_tp`
- elle doit se situer dans le dossier standard pour votre utilisateur (c'est `~/.ssh`)
- elle doit utiliser l'algorithme que vous avez choisi à l'étape précédente (donc, pas de RSA)
- elle est protégée par un mot de passe (*passphrase*) de votre choix

> Dans le compte-rendu, donnez toutes les commandes de génération de la clé. Prouvez aussi avec un `ls` sur votre clé qu'elle existe bien, au bon endroit.

```
PS C:\Users\emrep> ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\cloud_tp"
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in C:\Users\emrep\.ssh\cloud_tp
Your public key has been saved in C:\Users\emrep\.ssh\cloud_tp.pub
```

```
PS C:\Users\emrep\.ssh> ls cloud_tp*


    Répertoire : C:\Users\emrep\.ssh


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        29/10/2025     11:05            464 cloud_tp
-a----        29/10/2025     11:05            104 cloud_tp.pub
```

### C. Agent SSH

🌞 **Configurer un agent SSH sur votre poste**

- détaillez-moi toute la conf ici que vous aurez fait
- vous n'utiliserez QUE la ligne de commande, peu importe l'OS

??? note

    Au cas où j'ai besoin de le préciser : **les Windowsiens**, ça c'est obligé : vous le faites uniquement avec Powershell, votre shell natif.  
    L'agent SSH c'est natif sous Windows aussi normalement.

```
PS C:\WINDOWS\system32> Set-Service -Name ssh-agent -StartupType Automatic
PS C:\WINDOWS\system32> Start-Service ssh-agent
PS C:\WINDOWS\system32> Get-Service ssh-agent

Status   Name               DisplayName
------   ----               -----------
Running  ssh-agent          OpenSSH Authentication Agent
```

```
PS C:\Users\emrep> ssh-add $env:USERPROFILE\.ssh\cloud_tp
Enter passphrase for C:\Users\emrep\.ssh\cloud_tp:
Identity added: C:\Users\emrep\.ssh\cloud_tp (emrep@LAPTOP-82V3F554)
PS C:\Users\emrep> ssh-add -l
256 SHA256:YyMQiqGU8ICr91m7fmjjjdgU9MGoQvIkXVmGbYHCfzI emrep@LAPTOP-82V3F554 (ED25519)
```

```
PS C:\Users\emrep\.ssh> notepad $env:USERPROFILE/.ssh/config

Host VM1
  HostName 4.233.121.175
  User redz
  Port 22
  IdentityFile C:\Users\emrep\.ssh\cloud_tp
  StrictHostKeyChecking no
```