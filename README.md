# Opin Kerfi - Ansible Uppskriftir fyrir Windows

## Strúktúr
Allar skrár eiga að vera í lágstöfum og bannað er að nota bandstrik til aðgreiningar. Undirstrik eru leyfileg.

Nöfn eiga að vera lýsandi fyrir það sem playbook-in er að fara að gera og gott að miða við að nota orð eins og create, update, delete, install.

Þessi kóðahirsla hefur eftirfarandi strúktúr:
```shell
# Allar playbooks eru með dev_ forskeyti í þrófun.
development/.
├── monitoring
│   └── dev_adagios_agent_install.yml
├── operations
│   ├── common
│   └── ok365
└── surveys
    └── dev_create_domain_user_auto_test.yml
# Allar playbooks eru með test_ forskeyti í prófun.
test/
├── monitoring
│   └── test_adagios_agent_install.yml
└── operations
    ├── common
    │   ├── test_setja_inn_windows_uppfaerslur.yml
    │   └── test_setja_inn_windows_uppfaerslur_v2.yml
    └── ok365
# Allar playbooks eru án forskeytis í raunumhverfi.
production/
├── monitoring
│   └── adagios_agent_install.yml
└── operations
    ├── common
    │   ├── setja_inn_windows_uppfaerslur.yml
    │   └── setja_inn_windows_uppfaerslur_V2.yml
    └── ok365
```

## Undirbúningur á windows vél

Á vélinni sem á að stýra með Ansible opnið Windows PowerShell ISE og keyrið eftirfarandi:

```powershell
$url = "https://raw.githubusercontent.com/opinkerfi/ok-ansible-windows/master/powershell_scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)

powershell.exe -ExecutionPolicy ByPass -File $file
```

Það sem þessi skrifta gerir er að sækja ```ConfigureRemoteForAnsible.ps1```skrituna sem stillir ```winrm``` af og opnar eldvegg fyrir winrm tengingar. 

__ATH:__ Ef stýrikerfið er 2008 eða windows 7 þarf að uppfæra powershell og .net framework sbr.  https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html#upgrading-powershell-and-net-framework

## Tips and Tricks

### Þróun á ansible módúlum 
__Sjá:__ https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general_windows.html

### Hjáleið vegna python bug með vagrant á osx

Export-a út eftifarandi breytu svo ansible keyri winrm aðgerðir án þess að stoppa.

```export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES```
