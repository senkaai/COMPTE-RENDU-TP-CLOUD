# III. Gestion de secrets

⚠️⚠️⚠️ **Dans cette partie, on bosse que avec `azure1.tp2`**

## 1. Un premier secret

➜ **Créer un *Key Vault***

```powershell
PS C:\Users\emrep> az account show -o table
EnvironmentName    HomeTenantId                          IsDefault    Name                State    TenantDefaultDomain    TenantDisplayName    TenantId
-----------------  ------------------------------------  -----------  ------------------  -------  ---------------------  -------------------  ------------------------------------
AzureCloud         413600cf-bd4e-4c7c-8a61-69e73cddf731  True         Azure for Students  Enabled  efrei.net              Efrei                413600cf-bd4e-4c7c-8a61-69e73cddf731

PS C:\Users\emrep> az provider register --namespace Microsoft.KeyVault
Registering is still on-going. You can monitor using 'az provider show -n Microsoft.KeyVault'
PS C:\Users\emrep> $rg="TT"; $loc="spaincentral"; $kv="*****"
PS C:\Users\emrep> az keyvault create -g $rg -n $kv -l $loc --sku standard -o table
Location      Name            ResourceGroup
------------  --------------  ---------------
spaincentral  kv-emrep-24163  TT
```

➜ **Créer un secret**

```powershell
PS C:\Users\emrep> az keyvault show -g TT -n ***** --query "{rbac:properties.enableRbacAuthorization,id:id}" -o table
Rbac
------
True
PS C:\Users\emrep> $me = az ad signed-in-user show --query id -o tsv
PS C:\Users\emrep> $kvId = az keyvault show -g TT -n ***** --query id -o tsv
PS C:\Users\emrep> az role assignment create --assignee-object-id $me --assignee-principal-type User --role "Key Vault Secrets Officer" --scope $kvId -o table
CreatedOn                         Name                                  PrincipalId                           PrincipalType    ResourceGroup    RoleDefinitionId                                                                                                                            Scope                                                                                                                     UpdatedBy                             UpdatedOn
--------------------------------  ------------------------------------  ------------------------------------  ---------------  ---------------  ------------------------------------------------------------------------------------------------------------------------------------------  ------------------------------------------------------------------------------------------------------------------------  ------------------------------------  --------------------------------
2025-10-30T10:53:46.867835+00:00  4c0fa6c0-c86c-4a3a-9e20-ad69662e0438  0518a76d-9c75-48bc-aa87-5fb95db5689c  User             TT               /subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7  /subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/resourceGroups/TT/providers/Microsoft.KeyVault/vaults/kv-emrep-24163  0518a76d-9c75-48bc-aa87-5fb95db5689c  2025-10-30T10:53:47.112895+00:00

PS C:\Users\emrep> az keyvault secret set --vault-name kv-emrep-24163 -n TEST-SECRET --value "hello" -o table
Name         Value
-----------  -------
TEST-SECRET  hello
```

➜ **Activer la "*Managed Identity*"** pour votre VM `azure1.tp2`

```powershell
PS C:\Users\emrep> $rg="TT"; $vm="azure1.tp1"; $kv="********"
PS C:\Users\emrep> $kvId = az keyvault show -g $rg -n $kv --query id -o tsv
PS C:\Users\emrep> $principalId = az vm identity assign -g $rg -n $vm --query principalId -o tsv
ERROR: Long-running operation wait cancelled.
PS C:\Users\emrep> $principalId = az vm identity assign -g $rg -n $vm --query principalId -o tsv
PS C:\Users\emrep> if (-not $principalId) { $principalId = az vm show -g $rg -n $vm --query "identity.principalId" -o tsv }^C
PS C:\Users\emrep> $principalId = az vm identity assign -g $rg -n $vm --query principalId -o tsv
PS C:\Users\emrep> while (-not $principalId -or $principalId -eq "") {
>>   Start-Sleep -Seconds 5
>>   $principalId = az vm show -g $rg -n $vm --query "identity.principalId" -o tsv
>> }
PS C:\Users\emrep> az role assignment create `
>>   --assignee-object-id $principalId `
>>   --assignee-principal-type ServicePrincipal `
>>   --role "Key Vault Secrets User" `
>>   --scope $kvId -o table
CreatedOn                         Name                                  PrincipalId                           PrincipalType     ResourceGroup    RoleDefinitionId                                                                                                                            Scope                                                                                                                     UpdatedBy                             UpdatedOn
--------------------------------  ------------------------------------  ------------------------------------  ----------------  ---------------  ------------------------------------------------------------------------------------------------------------------------------------------  ------------------------------------------------------------------------------------------------------------------------  ------------------------------------  --------------------------------
2025-10-30T11:48:39.545288+00:00  d3448cbf-dafd-4efc-962d-d7624669860f  6262ad59-7851-496d-bfc5-afdbf57b5b52  ServicePrincipal  TT               /subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6  /subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/resourceGroups/TT/providers/Microsoft.KeyVault/vaults/*** 0518a76d-9c75-48bc-aa87-5fb95db5689c  2025-10-30T11:48:39.774287+00:00
```

➜ **Configurer une *Access policy***

```powershell
PS C:\Users\emrep> $kvId = az keyvault show -g $rg -n $kv --query id -o tsv
PS C:\Users\emrep> $principalId = az vm identity assign -g $rg -n $vm --query principalId -o tsv
PS C:\Users\emrep> while (-not $principalId -or $principalId -eq "") {
>>   Start-Sleep -Seconds 5
>>   $principalId = az vm show -g $rg -n $vm --query "identity.principalId" -o tsv
>> }
PS C:\Users\emrep> az role assignment create `
>>   --assignee-object-id $principalId `
>>   --assignee-principal-type ServicePrincipal `
>>   --role "Key Vault Secrets User" `
>>   --scope $kvId -o table
CreatedBy                             CreatedOn                         Name                                  PrincipalId                           PrincipalName                         PrincipalType     ResourceGroup    RoleDefinitionId                                                                                                                            RoleDefinitionName      Scope                                                                                                                     UpdatedBy                             UpdatedOn
------------------------------------  --------------------------------  ------------------------------------  ------------------------------------  ------------------------------------  ----------------  ---------------  ------------------------------------------------------------------------------------------------------------------------------------------  ----------------------  ------------------------------------------------------------------------------------------------------------------------  ------------------------------------  --------------------------------
0518a76d-9c75-48bc-aa87-5fb95db5689c  2025-10-30T11:48:39.774287+00:00  d3448cbf-dafd-4efc-962d-d7624669860f  6262ad59-7851-496d-bfc5-afdbf57b5b52  865cc2eb-c5a1-4444-ba77-42ffbe9fd21e  ServicePrincipal  TT               /subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6  Key Vault Secrets User  /subscriptions/69087ab6-ed64-449b-95b6-d2d44f85dae7/resourceGroups/TT/providers/Microsoft.KeyVault/vaults/kv-emrep-24163  0518a76d-9c75-48bc-aa87-5fb95db5689c  2025-10-30T11:48:39.774287+00:00
```

🌞 **Récupérer votre secret depuis la VM**

- vous vous connectez en SSH à `azure1.tp2`
- téléchargez le CLI `az` (suivez la doc officielle, y'a un paquet normalement)
- puis :

```bash
azureuser@azure1:~$ az login --identity
******

azureuser@azure1:~$ az keyvault secret show --vault-name kv-emrep-24163 --name TEST-SECRET
************
```

## 2. Gérer les secrets de l'application

### A. Script pour récupérer les secrets

➜ **Créer un nouveau secret dans votre *Key Vault***

- appelez-le `DB_PASSWORD`
- le secret c'est donc "meow" (super secret :d)

```powershell
PS C:\Users\emrep> az keyvault secret set --vault-name ***** -n DB-PASSWORD --value "meow" -o table
Name         Value
-----------  -------
DB-PASSWORD  ****
```

🌞 **Coder un ptit script `bash` : `get_secrets.sh`**

- il commence probablement par un `az login --identity` 
- il récupère le secret `DB_PASSWORD` (commande `az`, stocke dans une variable)
- il l'injecte dans le fichier `.env`

    - commande `sed` ou autres
    - il remplace la valeur de `DB_PASSWORD=` par le secret récupéré avec la commande `az`

```bash
azureuser@azure1:/opt$ echo "DB_PASSWORD=****" | sudo tee /opt/webapp/.env >/dev/null^C
azureuser@azure1:/opt$ sudo mkdir -p /opt/webapp
azureuser@azure1:/opt$ echo "DB_PASSWORD=****" | sudo tee /opt/webapp/.env >/dev/null
azureuser@azure1:/opt$ id webapp >/dev/null 2>&1 || sudo useradd -r -s /usr/sbin/nologin -d /opt/webapp webapp
azureuser@azure1:/opt$ sudo chown -R webapp:webapp /opt/webapp
azureuser@azure1:/opt$ cd /tmp
azureuser@azure1:/tmp$ sudo tee /usr/local/bin/get_secrets.sh >/dev/null <<'EOF'
```

```bash
azureuser@azure1:/tmp$ sudo tee /usr/local/bin/get_secrets.sh >/dev/null <<'EOF'
> #!/usr/bin/env bash
set -euo pipefail
KV_NAME="${KV_NAME:-*****}"
ENV_FILE="${ENV_FILE:-/opt/webapp/.env}"
upsert_env(){ local v="$1" x="$2" f="$3"; sudo mkdir -p "$(dirname "$f")"; sudo touch "$f"; if grep -qE "^${v}=" "$f"; then sudo sed -i -E "s#^${v}=.*#${v}=${x}#" "$f"; else echo "${v}=${x}" | sudo tee -a "$f" >/dev/null; fi; }
az login --identity 1>/dev/null
DB_PASS="$(az keyvault secret show --vault-name "$KV_NAME" --name DB-PASSWORD --query value -o tsv 2>/dev/null || true)"
[ -n "${DB_PASS:-}" ] && upsert_env "DB_PASSWORD" "$DB_PASS" "$ENV_FILE"
EOF
```

🌞 **Environnement du script `get_secrets.sh`**, il doit :

- être stocké dans `/usr/local/bin` sur `azure1.tp2` (commande `mv`)
- appartenir à l'utilisateur `webapp` (commande `chown`)
- être exécutable (commande `chmod`)
- être inutilisable par les "autres" (ni `r`, ni `w`, ni `x`)

```bash
azureuser@azure1:~$ ls -l /usr/local/bin/get_secrets.sh
-rwx------ 1 webapp webapp 570 Oct 31 12:30 /usr/local/bin/get_secrets.sh
```

```bash
azureuser@azure1:~$ grep '^DB_PASSWORD=' /opt/webapp/.env
DB_PASSWORD=DUMMY
azureuser@azure1:~$ sudo /usr/local/bin/get_secrets.sh
azureuser@azure1:~$ grep '^DB_PASSWORD=' /opt/webapp/.env
DB_PASSWORD=meow
```
### B. Exécution automatique

🌞 **Ajouter le script en `ExecStartPre=` dans `webapp.service`**

```bash
azureuser@azure1:~$ sudo nano /etc/systemd/system/webapp.service

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
ExecStartPre=/usr/local/bin/get_secrets.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

🌞 **Prouvez que la ligne en `ExecStartPre=` a bien été exécutée**
```bash
    Process: 22721 ExecStartPre=/usr/local/bin/get_secrets.sh (code=exited, status=0/SUCCESS)
```

```bash
azureuser@azure1:~$ sudo sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=DUMMY/' /opt/meow/.env
azureuser@azure1:~$ sudo systemctl restart webapp
azureuser@azure1:~$ grep '^DB_PASSWORD=' /opt/meow/.env
DB_PASSWORD=***
```
### C. Secret Flask

🌞 **Intégrez la gestion du secret Flask dans votre script `get_secrets.sh`**

```bash
azureuser@azure1:~$ openssl rand -hex 32 | tee /tmp/flask.hex
****
azureuser@azure1:~$ az login --use-device-code
Retrieving tenants and subscriptions for the selection...

[Tenant and subscription selection]

No     Subscription name    Subscription ID                       Tenant
-----  -------------------  ------------------------------------  --------
[1] *  Azure for Students   6***********************************  Efrei

[Warning] The login output has been updated. Please be aware that it no longer displays the full list of available subscriptions by default.
azureuser@azure1:~$ az keyvault secret set --vault-name ****** -n FLASK-SECRET-KEY --value "$(cat /tmp/flask.hex
)" -o table
Name              Value
----------------  ----------------------------------------------------------------
FLASK-SECRET-KEY  ***************************************************************
azureuser@azure1:~$ az logout
azureuser@azure1:~$ az login --identity
```

🌞 **Redémarrer le service**

```bash
azureuser@azure1:~$ sudo sed -i 's/^FLASK_SECRET_KEY=.*/FLASK_SECRET_KEY=DUMMY/' /opt/meow/.env || true
azureuser@azure1:~$ sudo systemctl restart webapp
azureuser@azure1:~$ grep -E '^(DB_PASSWORD|FLASK_SECRET_KEY)=' /opt/meow/.env
DB_PASSWORD=meow
FLASK_SECRET_KEY=acbc4fe9a5c9fdc41daeeda84146e521fa55f89868401d0ea0f641c048a93479
azureuser@azure1:~$ systemctl status webapp --no-pager | grep -m1 'ExecStartPre='
    Process: 34402 ExecStartPre=/usr/local/bin/get_secrets.sh (code=exited, status=0/SUCCESS)
```

📁 **Dans le dépôt git : votre dernière version de `get_secrets.sh`**
