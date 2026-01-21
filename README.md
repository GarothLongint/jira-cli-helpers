# Jira CLI Helpers

Zestaw pomocniczych funkcji bash do zarządzania zadaniami w Jira z linii komend.

## Instalacja

1. Sklonuj repozytorium:
```bash
git clone https://github.com/GarothLongint/jira-cli-helpers.git
cd jira-cli-helpers
```

2. Użyj interaktywnej konfiguracji:
```bash
source jira-helpers.sh
jira-init
```

Komenda `jira-init` przeprowadzi Cię przez konfigurację:
- Poprosi o dane do połączenia z Jira (URL, token, projekt)
- Utworzy plik konfiguracyjny z bezpiecznymi uprawnieniami (600)
- Zaoferuje dodanie skryptu do shell startup (~/.zshrc lub ~/.bashrc)

### Ręczna konfiguracja (alternatywna metoda)

```bash
cp jira-config.dist ~/.jira-config
nano ~/.jira-config  # Wypełnij swoimi danymi
chmod 600 ~/.jira-config
source ~/path/to/jira-helpers.sh
```

## Konfiguracja

Plik `~/.jira-config` zawiera:
- `JIRA_URL` - URL instancji Jira
- `JIRA_USER` - Twój email w Jira
- `JIRA_TOKEN` - API token (Personal Access Token)
- `JIRA_PROJECT` - Domyślny klucz projektu
- `JIRA_USER_ID` - Twoje ID użytkownika (z `/rest/api/2/myself`)
- `JIRA_BOARD_ID` - ID board do operacji sprint
- `JIRA_STORY_POINTS_FIELD` - ID pola story points (zwykle `customfield_10040`)

### Wiele konfiguracji (konteksty)

Możesz mieć wiele konfiguracji dla różnych projektów lub użytkowników:

```bash
# Utwórz nową nazwana konfigurację
jira-init projekt2

# Przełączaj się między kontekstami
jira-ctx
# Wybierz numer z listy lub:
jira-ctx projekt2  # Przełącz się bezpośrednio
jira-ctx default   # Wróć do domyślnej konfiguracji
```

## Dostępne komendy

### Inicjalizacja i zarządzanie kontekstami
- `jira-init [nazwa]` - interaktywna konfiguracja (opcjonalnie z nazwą dla wielu kontekstów)
- `jira-ctx [nazwa]` - przełączanie między konfiguracjami z interaktywnym menu

### Zarządzanie zadaniami
- `jira-create "Tytuł" ["Opis"] [Type]` - tworzy zadanie (domyślnie Task)
- `jira-task ["Tytuł"] ["Opis"]` - szybkie tworzenie zadania typu Task z trybem interaktywnym
- `jira-list [limit]` - listuje ostatnie zadania (domyślnie 10)
- `jira-get DEV1-123` - szczegóły zadania
- `jira-assign-me DEV1-123` - przypisz zadanie do siebie
- `jira-comment DEV1-123 "Komentarz"` - dodaj komentarz
- `jira-search "JQL" [limit]` - wyszukiwanie z użyciem JQL
- `jira-story-points DEV1-123 5` - ustaw story points
- `jira-update DEV1-123 "Nowy opis"` - aktualizuj opis zadania
- `jira-transition DEV1-123 "Done"` - zmień status zadania
- `jira-mark-done DEV1-123` - oznacz zadanie jako Done (próbuje różne ścieżki workflow)

### Zarządzanie sprintem
- `jira-my-tasks [status]` - pokaż moje zadania (domyślnie: "In Progress,To Do,New")
- `jira-active-sprint` - pokaż aktywny sprint i jego ID
- `jira-move-to-sprint "DEV1-123,DEV1-124" SPRINT_ID` - przenieś zadania do sprintu

### Przykłady użycia

```bash
# Pierwsza konfiguracja
jira-init
# Postępuj zgodnie z instrukcjami

# Utwórz dodatkową konfigurację dla innego projektu
jira-init projekt2

# Przełącz się między kontekstami
jira-ctx
# Wybierz [1] lub [2] z menu

# Utwórz zadanie - tradycyjna metoda
jira-create "Naprawa błędu w koszyku" "Koszyk nie przelicza ceny" "Bug"

# Utwórz zadanie typu Task - szybka metoda
jira-task "Dodać walidację formularza" "Walidacja email i numeru telefonu"

# Utwórz zadanie w trybie interaktywnym (bez parametrów)
jira-task
# System zapyta o tytuł i opis

# Lista zadań
jira-list 5

# Przypisz do siebie i ustaw story points
jira-assign-me DEV1-1234
jira-story-points DEV1-1234 3

# Zmień status i oznacz jako Done
jira-transition DEV1-1234 "In Progress"
jira-mark-done DEV1-1234

# Wyszukiwanie
jira-search "assignee=currentUser() AND status=Open"

# Zarządzanie sprintem
jira-my-tasks "New"  # Pokaż tylko nowe zadania
jira-active-sprint  # Sprawdź ID aktywnego sprintu
jira-move-to-sprint "DEV1-1706,DEV1-1705" 42492  # Przenieś zadania do sprintu
```

## Wymagania

- `bash` lub `zsh` (Linux/macOS) lub Git Bash/WSL (Windows)
- `curl`
- `jq`
- Dostęp do instancji Jira z włączonym API

## Wsparcie dla Windows

Projekt działa na Windows przez:
- **Git Bash** - zalecane, proste w użyciu
- **WSL (Windows Subsystem for Linux)** - pełna kompatybilność
- **PowerShell** - wymaga przepisania funkcji (w planach)

Szczegółową instrukcję instalacji na Windows znajdziesz w [WINDOWS.md](WINDOWS.md)

## Licencja

MIT
