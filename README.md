# Русская локализация OpenHands Agent Canvas / Russian localization for OpenHands Agent Canvas

> **⚠ Примечание / Note (RU):** автоматический скрипт `install.sh` проверен в тестовой
> среде, но не «в дикой природе» на разных конфигурациях. Если что-то пойдёт не так —
> используйте **ручной способ** (раздел ниже): он прозрачен и состоит из трёх команд
> и одной правки файла.
>
> **⚠ Note (EN):** the `install.sh` automation was tested in a sandbox but not on a wide
> range of setups. If anything goes wrong, use the **manual method** below — it is
> transparent: three commands plus one file edit.

---

## 🇷🇺 Русский

### Что это

Полный перевод интерфейса **OpenHands Agent Canvas** на русский язык:

- Файл: `openhands.json` — **2486 из 2486 строк** (100% покрытия, структура зеркалирует английский файл)
- Базовая версия: Agent Canvas **1.24.0** (agent-server 1.49.6)
- Проверено: только строки интерфейса, **никаких ключей/токенов/личных данных**

| Файл репозитория | Назначение |
|---|---|
| `openhands.json` | сам перевод |
| `install.sh` | автоматический установщик (см. ниже) |
| `INSTALL.md` | эта инструкция |

### Способ 1 — автоматический (скрипт)

Одна команда:

```bash
curl -fsSL https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/install.sh | bash
```

Скрипт:

1. найдёт установленный Agent Canvas (по умолчанию `/opt/agent-canvas/frontend`; нестандартный путь — через `AGENT_CANVAS_FRONTEND=/путь`),
2. скачает перевод из этого репозитория, проверит валидность JSON и совпадение количества ключей с вашей версией,
3. установит его в `locales/ru/openhands.json`,
4. покажет **какую именно правку и в какой файл** нужно внести, чтобы «Русский» появился в переключателе языков, проверит, что шаблон замены встречается ровно один раз, и спросит подтверждение — правка вносится только после `Y`.

Автоматически применить правку без вопроса (для CI/скриптов):

```bash
curl -fsSL https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/install.sh | bash -s -- --yes
```

Если у вашей учётной записи нет прав на `/opt`, запустите под root:

```bash
curl -fsSL https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/install.sh | sudo bash
```

Перед применением правки скрипт сам создаёт резервную копию бандла
(`<файл>.bak-<дата>`), откат — вернуть этот файл на место.

> **Осторожность прежде всего:** команда `curl | bash` исполняет код из интернета.
> Если не хотите так — скачайте скрипт, просмотрите и запустите:
>
> ```bash
> curl -fsSL -o install.sh https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/install.sh
> less install.sh        # просмотреть
> bash install.sh        # запустить
> ```

### Способ 2 — ручной (рекомендуется, если скрипт не сработал)

**Шаг 1.** Скачать перевод и положить его к другим языкам:

```bash
sudo mkdir -p /opt/agent-canvas/frontend/locales/ru
sudo curl -fsSL -o /opt/agent-canvas/frontend/locales/ru/openhands.json \
  https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/openhands.json
```

**Шаг 2.** Найти файл бандла со списком языков (имя содержит hash и меняется между версиями):

```bash
grep -rl 'value:`uk`' /opt/agent-canvas/frontend/assets/
```

**Шаг 3.** В найденном файле найти конец списка языков:

```
{label:`Українська`,value:`uk`}]
```

и дописать русский **перед** закрывающей `]`, чтобы получилось:

```
{label:`Українська`,value:`uk`},{label:`Русский`,value:`ru`}]
```

(правка требует root; рекомендация — сначала сделать копию файла).

**Шаг 4.** Полностью обновить страницу (Ctrl+Shift+R) и выбрать язык:
**Settings → Application → Language → «Русский»**, либо открыть `http://<хост>/canvas/?lng=ru`.
Выбор сохраняется автоматически (localStorage, ключ `i18nextLng`).

### Обновление Agent Canvas

1. Каталог `locales/` может быть пересоздан — повторите шаг 1 (или снова запустите скрипт: он обновит файл).
2. Имя файла бандла изменится — повторите шаги 2–3 ручного способа (или запустите скрипт).
3. Новые строки интерфейса до обновления перевода будут показываться на английском (встроенный fallback).

### Откат

```bash
sudo rm -rf /opt/agent-canvas/frontend/locales/ru
# бандл: восстановить из <файл>.bak-<дата>, созданного скриптом, либо убрать
# «,{label:`Русский`,value:`ru`}` из списка языков вручную
```

---

## 🇬🇧 English

### What this is

A complete Russian translation of the **OpenHands Agent Canvas** UI:

- File: `openhands.json` — **2486 of 2486 strings** (100% coverage, mirrors the English file)
- Baseline: Agent Canvas **1.24.0** (agent-server 1.49.6)
- Verified: UI strings only, **no keys / tokens / personal data**

| Repository file | Purpose |
|---|---|
| `openhands.json` | the translation itself |
| `install.sh` | automated installer (see below) |
| `INSTALL.md` | this guide |

### Method 1 — automated (script)

One command:

```bash
curl -fsSL https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/install.sh | bash
```

The script:

1. locates the installed Agent Canvas (default `/opt/agent-canvas/frontend`; override with `AGENT_CANVAS_FRONTEND=/path`),
2. downloads the translation from this repository, validates the JSON and compares key counts against your version,
3. installs it as `locales/ru/openhands.json`,
4. shows **exactly which edit and in which file** is needed to make «Русский» appear in the language switcher, verifies the replacement pattern occurs exactly once, and asks for confirmation — the edit is applied only after `Y`.

To apply the patch without prompting (CI / scripted use):

```bash
curl -fsSL https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/install.sh | bash -s -- --yes
```

If your account lacks write access to `/opt`, run as root:

```bash
curl -fsSL https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/install.sh | sudo bash
```

Before patching, the script automatically backs up the bundle (`<file>.bak-<date>`);
to roll back, restore that file.

> **Safety first:** `curl | bash` executes code from the internet. If you prefer not to,
> download, review, then run:
>
> ```bash
> curl -fsSL -o install.sh https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/install.sh
> less install.sh        # review
> bash install.sh        # run
> ```

### Method 2 — manual (recommended if the script fails)

**Step 1.** Download the translation next to the other languages:

```bash
sudo mkdir -p /opt/agent-canvas/frontend/locales/ru
sudo curl -fsSL -o /opt/agent-canvas/frontend/locales/ru/openhands.json \
  https://raw.githubusercontent.com/Ghostivity/Russian-openhands.json/main/openhands.json
```

**Step 2.** Locate the bundle file with the language list (the name contains a hash and changes between versions):

```bash
grep -rl 'value:`uk`' /opt/agent-canvas/frontend/assets/
```

**Step 3.** In that file find the end of the language list:

```
{label:`Українська`,value:`uk`}]
```

and insert Russian **before** the closing `]`, so it becomes:

```
{label:`Українська`,value:`uk`},{label:`Русский`,value:`ru`}]
```

(editing requires root; make a copy of the file first).

**Step 4.** Hard-refresh the page (Ctrl+Shift+R) and pick the language:
**Settings → Application → Language → «Русский»**, or open `http://<host>/canvas/?lng=ru`.
The choice persists automatically (localStorage key `i18nextLng`).

### Updating Agent Canvas

1. The `locales/` directory may be recreated — repeat step 1 (or just re-run the script).
2. The bundle filename changes — repeat steps 2–3 of the manual method (or re-run the script).
3. Newly added UI strings will show in English until the translation is extended (built-in fallback).

### Rollback

```bash
sudo rm -rf /opt/agent-canvas/frontend/locales/ru
# bundle: restore from the <file>.bak-<date> copy created by the script, or manually
# remove `,{label:`Русский`,value:`ru`}` from the language list
```

---

*Agent Canvas is MIT-licensed; the translation is a derivative work of the same scope.*
