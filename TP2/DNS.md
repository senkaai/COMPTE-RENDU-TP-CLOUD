# I. Un p'tit nom DNS

Mini-partie pour définir un nom DNS à votre machine.

➜ **Définissez un nom de domaine pour joindre notre `azure1.tp2`**

- WebUI ou CLI donc
- le nom de domaine est associé à l'IP publique portée par l'interface de `azure1.tp2` (genre il est pas associé à la VM directement)
- le nom que vous choisissez doit contenir `meow`

🌞 **Prouvez que c'est effectif**

- une ou plusieurs commande(s) `az` qui retourne(nt) :

    - la VM (genre au moins son nom)
    - l'IP publique
    - le nom DNS associé

- un `curl` fonctionnel vers le nom de domaine

    - comme d'hab, juste quelques lignes de la sortie, mettez pas tout :d
  
```powershell
PS C:\Users\emrep> az vm list-ip-addresses | grep ipAddress
            "ipAddress": "4.233.121.175",
            "ipAddress": "158.158.48.205",
PS C:\Users\emrep> az vm list-ip-addresses | grep name
      "name": "VM1",
            "name": "VM1-ip",
      "name": "azure1.tp1",
            "name": "azure1.tp1PublicIP",
      "name": "azure2.tp1",
```

```bash
azureuser@azure1:~$ curl -I meow.spaincentral.cloudapp.azure.com:8000
HTTP/1.1 200 OK
Server: Werkzeug/3.1.3 Python/3.12.3
Date: Thu, 30 Oct 2025 11:56:55 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 12566
```
  
