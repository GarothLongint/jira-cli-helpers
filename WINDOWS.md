# Jira CLI Helpers - Windows Installation

## Opcje instalacji dla Windows

### Opcja 1: Git Bash (Zalecane)

Git Bash zawiera środowisko bash kompatybilne z Linux/macOS.

1. **Zainstaluj Git for Windows**
   - Pobierz z https://git-scm.com/download/win
   - Podczas instalacji upewnij się, że zaznaczono "Git Bash"

2. **Uruchom Git Bash**

3. **Sklonuj repozytorium**
   ```bash
   cd ~
   git clone https://github.com/GarothLongint/jira-cli-helpers.git
   cd jira-cli-helpers
   ```

4. **Konfiguracja**
   ```bash
   source jira-helpers.sh
   jira-init
   ```

5. **Dodaj do profilu Git Bash**
   ```bash
   echo 'source ~/jira-cli-helpers/jira-helpers.sh' >> ~/.bashrc
   ```

### Opcja 2: WSL (Windows Subsystem for Linux)

WSL zapewnia pełne środowisko Linux w Windows 10/11.

1. **Zainstaluj WSL**
   ```powershell
   # W PowerShell jako Administrator
   wsl --install
   ```

2. **Uruchom WSL (domyślnie Ubuntu)**
   
3. **Zainstaluj wymagane narzędzia**
   ```bash
   sudo apt update
   sudo apt install curl jq git
   ```

4. **Sklonuj i konfiguruj**
   ```bash
   cd ~
   git clone https://github.com/GarothLongint/jira-cli-helpers.git
   cd jira-cli-helpers
   source jira-helpers.sh
   jira-init
   ```

5. **Dodaj do profilu**
   ```bash
   echo 'source ~/jira-cli-helpers/jira-helpers.sh' >> ~/.bashrc
   ```

### Opcja 3: PowerShell (Port funkcji)

Możliwe jest stworzenie wersji PowerShell. Przykład podstawowej funkcji:

```powershell
# jira-helpers.ps1

$env:JIRA_CONFIG_FILE = "$HOME\.jira-config"

function Jira-List {
    param(
        [int]$Limit = 10
    )
    
    $config = Get-Content $env:JIRA_CONFIG_FILE | ConvertFrom-StringData
    
    $headers = @{
        "Authorization" = "Bearer $($config.JIRA_TOKEN)"
        "Content-Type" = "application/json"
    }
    
    $jql = "project=$($config.JIRA_PROJECT)+order+by+created+DESC"
    $url = "$($config.JIRA_URL)/rest/api/2/search?jql=$jql&maxResults=$Limit"
    
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    
    foreach ($issue in $response.issues) {
        Write-Output "$($issue.key): $($issue.fields.summary) [$($issue.fields.status.name)]"
    }
}
```

## Wymagania

### Git Bash / WSL
- Git (dla Git Bash)
- curl (zwykle wbudowane)
- jq (w WSL: `sudo apt install jq`)

### PowerShell
- PowerShell 5.1+ lub PowerShell Core 7+
- Dostęp do internetu

## Testowanie instalacji

Po instalacji sprawdź:

```bash
# Bash / Git Bash / WSL
jira-list 5
jira-my-tasks

# PowerShell
Jira-List -Limit 5
```

## Znane ograniczenia

### Git Bash
- Może wymagać konwersji znaków końca linii (LF zamiast CRLF)
- Niektóre ścieżki mogą wymagać użycia notacji Windows (`C:/Users/...`)

### WSL
- Pliki konfiguracyjne są oddzielone od Windows
- Do edycji plików w WSL używaj `nano`, `vim` lub `code .` (VS Code)

### PowerShell
- Wymaga przepisania wszystkich funkcji z bash na PowerShell
- Składnia funkcji jest inna niż w bash

## Rozwiązywanie problemów

### Git Bash: "bad interpreter" lub błędy CRLF
```bash
dos2unix jira-helpers.sh
# lub
sed -i 's/\r$//' jira-helpers.sh
```

### WSL: Brak curl lub jq
```bash
sudo apt update
sudo apt install curl jq
```

### PowerShell: Polityka wykonywania skryptów
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Rekomendacja

**Dla użytkowników Windows 10/11**: Zalecamy **WSL** lub **Git Bash**
- WSL: Najlepsza kompatybilność z oryginalnymi skryptami bash
- Git Bash: Szybszy start, nie wymaga WSL

**Dla PowerShell**: Możliwe, ale wymaga dodatkowej pracy nad portem funkcji
