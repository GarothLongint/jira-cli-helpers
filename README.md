# Jira CLI Helpers

Zestaw pomocniczych funkcji bash do zarządzania zadaniami w Jira z linii komend.

## Instalacja

1. Sklonuj repozytorium:
```bash
git clone https://github.com/GarothLongint/jira-cli-helpers.git
cd jira-cli-helpers
```

2. Skopiuj i skonfiguruj:
```bash
cp jira-config.dist ~/.jira-config
nano ~/.jira-config  # Wypełnij swoimi danymi
chmod 600 ~/.jira-config
```

3. Załaduj skrypt do swojego shell:
```bash
# Dodaj do ~/.zshrc lub ~/.bashrc:
source ~/path/to/jira-helpers.sh
```

## Konfiguracja

Plik `~/.jira-config` musi zawierać:
- `JIRA_URL` - URL instancji Jira
- `JIRA_USER` - Twój email w Jira
- `JIRA_TOKEN` - API token (Personal Access Token)
- `JIRA_PROJECT` - Domyślny klucz projektu
- `JIRA_USER_ID` - Twoje ID użytkownika (z `/rest/api/2/myself`)
- `JIRA_BOARD_ID` - ID board do operacji sprint
- `JIRA_STORY_POINTS_FIELD` - ID pola story points (zwykle `customfield_10040`)

## Dostępne komendy

### Zarządzanie zadaniami
- `jira-create "Tytuł" ["Opis"] [Type]` - tworzy zadanie (domyślnie Task)
- `jira-list [limit]` - listuje ostatnie zadania (domyślnie 10)
- `jira-get DEV1-123` - szczegóły zadania
- `jira-assign-me DEV1-123` - przypisz zadanie do siebie
- `jira-comment DEV1-123 "Komentarz"` - dodaj komentarz
- `jira-search "JQL" [limit]` - wyszukiwanie z użyciem JQL
- `jira-story-points DEV1-123 5` - ustaw story points

### Przykłady użycia

```bash
# Utwórz zadanie
jira-create "Naprawa błędu w koszyku" "Koszyk nie przelicza ceny" "Bug"

# Lista zadań
jira-list 5

# Przypisz do siebie i ustaw story points
jira-assign-me DEV1-1234
jira-story-points DEV1-1234 3

# Wyszukiwanie
jira-search "assignee=currentUser() AND status=Open"
```

## Wymagania

- `bash` lub `zsh`
- `curl`
- `jq`
- Dostęp do instancji Jira z włączonym API

## Licencja

MIT
