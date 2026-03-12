Конфиги для run_zapret.sh (Linux/nfqws).
Файлы здесь генерируются скриптом bat-to-linux-configs.ps1 из .bat конфигов.

Не редактируйте .conf вручную — после обновления .bat запустите:
  .\bat-to-linux-configs.ps1

Соответствие имён:
  default.conf     — копия general.bat (run_zapret.sh без аргументов)
  general.conf     — general.bat
  general_ALT.conf — general (ALT).bat
  general_SIMPLE_FAKE.conf — general (SIMPLE FAKE).bat
  и т.д.

Использование на Linux:
  ./run_zapret.sh list         # показать конфиги
  ./run_zapret.sh default
  ./run_zapret.sh general
  ./run_zapret.sh general_ALT

Переменная окружения CONFIG_DIR — путь к каталогу с конфигами (по умолчанию: ../zapret-discord-youtube-1.9.5/linux-configs или ./linux-configs).

Каталог fake/ с .bin файлами:
  Если в этой папке (рядом с run_zapret.sh) есть подкаталог fake/, скрипт берёт оттуда все .bin (tls_clienthello_*.bin, quic_initial_*.bin и т.д.). Иначе используется /opt/zapret_standalone/zapret/files/fake из репозитория zapret.
  Для конфигов вроде general_ALT11 нужны файлы из zapret-discord-youtube (папка bin/): скопируйте содержимое bin/ в linux-configs/fake/ на устройстве. Нужны минимум: quic_initial_www_google_com.bin, tls_clienthello_www_google_com.bin; для части конфигов — tls_clienthello_4pda_to.bin, tls_clienthello_max_ru.bin.
