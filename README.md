# zapret-discord-youtube

Конфигурации [zapret](https://github.com/bol-van/zapret) для обхода DPI (Discord, YouTube и др.) на Windows и Linux.

## Содержимое

- **Windows:** `.bat`-конфиги для запуска через winws (папка с проектом, `general*.bat`).
- **Linux:** скрипт `run_zapret.sh` и конфиги в папке `linux-configs/` для nfqws (iptables + NFQUEUE).
- **Конвертер:** `bat-to-linux-configs.ps1` — переводит `.bat` в `.conf` для Linux после обновления конфигов.

## Требования

- **Windows:** [zapret](https://github.com/bol-van/zapret), папка `bin/` с winws и .bin-файлами.
- **Linux:** root, iptables, nfqws (скрипт может скачать zapret и собрать nfqws при первом запуске).

## Использование на Windows

1. Запустить нужный `general*.bat` (например, `general (ALT11).bat`).
2. После изменения конфигов заново сгенерировать Linux-конфиги:
   ```powershell
   .\bat-to-linux-configs.ps1
   ```

## Использование на Linux

1. Скопировать на устройство папку `linux-configs/` (в ней `run_zapret.sh` и `*.conf`).
2. Для конфигов вроде `general_ALT11` положить .bin-файлы в `linux-configs/fake/` (скопировать из Windows-папки `bin/`).
3. Запуск:
   ```bash
   ./run_zapret.sh list              # список конфигов
   sudo ./run_zapret.sh default      # конфиг по умолчанию
   sudo ./run_zapret.sh general_ALT11
   ```

Подробнее — в [linux-configs/README.txt](linux-configs/README.txt).

## Структура репозитория

```
├── README.md
├── bat-to-linux-configs.ps1    # конвертер .bat → .conf
├── service.bat
├── general*.bat                # конфиги для Windows
├── lists/                      # списки хостов (general, exclude, ipset…)
├── linux-configs/
   ├── run_zapret.sh           # скрипт запуска nfqws на Linux
   ├── README.txt
   ├── *.conf                  # конфиги для nfqws (генерируются из .bat)
   └── fake/                   # сюда класть .bin (quic_*, tls_clienthello_*)

```

## Лицензия

MIT (см. [LICENSE](LICENSE)). Zapret — отдельный проект со своей лицензией.
