#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_NAME="${1:-default}"

if [ -n "$CONFIG_DIR" ]; then
  CONFIGS_DIR="$CONFIG_DIR"
elif [ -d "$SCRIPT_DIR/linux-configs" ]; then
  CONFIGS_DIR="$SCRIPT_DIR/linux-configs"
else
  CONFIGS_DIR="$SCRIPT_DIR"
fi

if [ "$CONFIG_NAME" = "list" ]; then
  echo "Доступные конфиги (файлы из $CONFIGS_DIR):"
  [ -d "$CONFIGS_DIR" ] && for f in "$CONFIGS_DIR"/*.conf; do
    [ -f "$f" ] && echo "  $(basename "$f" .conf)"
  done || echo "  (каталог не найден)"
  exit 0
fi

CONFIG_FILE="$CONFIGS_DIR/${CONFIG_NAME%.conf}.conf"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Ошибка: Конфиг не найден: $CONFIG_FILE"
  echo "Запустите: $0 list"
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Ошибка: Пожалуйста, запустите скрипт с правами root (sudo)."
  exit 1
fi

GAME_TCP_IPT="27015,27030"
GAME_UDP_IPT="27015:27030"

GAME_TCP_NFQ="27015,27030"
GAME_UDP_NFQ="27015-27030"

WORK_DIR="/opt/zapret_standalone"
LISTS_DIR="$WORK_DIR/lists"
QNUM=200

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) BIN_ARCH="x86_64" ;;
    aarch64) BIN_ARCH="aarch64" ;;
    armv7l|armv6l) BIN_ARCH="arm" ;;
    mips) BIN_ARCH="mips" ;;
    *) echo "Ошибка: Неподдерживаемая архитектура $ARCH"; exit 1 ;;
esac

echo "=> Определена архитектура: $ARCH ($BIN_ARCH)"

if [ ! -d "$WORK_DIR/zapret" ]; then
    echo "=> Скачивание репозитория zapret..."
    mkdir -p "$WORK_DIR"
    git clone --depth 1 https://github.com/bol-van/zapret.git "$WORK_DIR/zapret"
fi

BIN="$WORK_DIR/zapret/binaries/$BIN_ARCH/nfqws"
if [ ! -f "$BIN" ]; then
    BIN="$WORK_DIR/zapret/nfq/nfqws"
fi

if [ ! -f "$BIN" ]; then
    echo "=> Бинарный файл не найден. Начинаем компиляцию nfqws..."
    if ! command -v make &> /dev/null || ! command -v gcc &> /dev/null; then
        echo "=> Установка зависимостей для сборки..."
        apt update && apt install gcc make pkg-config libnetfilter-queue-dev libcap-dev -y
    fi
    make -C "$WORK_DIR/zapret"
    BIN="$WORK_DIR/zapret/nfq/nfqws"
    if [ ! -f "$BIN" ]; then
        echo "Ошибка: Не удалось скомпилировать nfqws."
        exit 1
    fi
    echo "=> Компиляция успешно завершена!"
fi

# Каталог с .bin (fake): свой fake/ рядом со скриптом или из репозитория zapret
if [ -d "$SCRIPT_DIR/fake" ]; then
  FAKE="$SCRIPT_DIR/fake"
  echo "=> Используются .bin из каталога: $FAKE"
else
  FAKE="$WORK_DIR/zapret/files/fake"
fi

mkdir -p "$LISTS_DIR"
for list in list-general.txt list-exclude.txt ipset-exclude.txt list-google.txt ipset-all.txt; do
    [ ! -f "$LISTS_DIR/$list" ] && touch "$LISTS_DIR/$list"
done

cleanup() {
    echo ""
    echo "=> Очистка правил iptables..."
    for chain in PREROUTING FORWARD OUTPUT; do
      iptables -t mangle -D $chain -p tcp -m multiport --dports 80,443,2053,2083,2087,2096,8443,$GAME_TCP_IPT -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null
      iptables -t mangle -D $chain -p udp -m multiport --dports 443 -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null
      iptables -t mangle -D $chain -p udp --dport 19294:19344 -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null
      iptables -t mangle -D $chain -p udp --dport 50000:50100 -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null
      iptables -t mangle -D $chain -p udp --dport $GAME_UDP_IPT -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null
    done
    echo "=> Работа завершена."
    exit 0
}
trap cleanup EXIT INT TERM

echo "=> Настройка правил iptables..."
for chain in PREROUTING FORWARD OUTPUT; do
  iptables -t mangle -I $chain -p tcp -m multiport --dports 80,443,2053,2083,2087,2096,8443,$GAME_TCP_IPT -j NFQUEUE --queue-num $QNUM --queue-bypass
  iptables -t mangle -I $chain -p udp -m multiport --dports 443 -j NFQUEUE --queue-num $QNUM --queue-bypass
  iptables -t mangle -I $chain -p udp --dport 19294:19344 -j NFQUEUE --queue-num $QNUM --queue-bypass
  iptables -t mangle -I $chain -p udp --dport 50000:50100 -j NFQUEUE --queue-num $QNUM --queue-bypass
  iptables -t mangle -I $chain -p udp --dport $GAME_UDP_IPT -j NFQUEUE --queue-num $QNUM --queue-bypass
done

echo "=> Запуск nfqws (конфиг: $CONFIG_NAME)..."
NFQWS_EXTRA_ARGS=()
while IFS= read -r line; do
  line="${line%$'\r'}"
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue
  line="${line//@FAKE@/$FAKE}"
  line="${line//@LISTS_DIR@/$LISTS_DIR}"
  line="${line//@GAME_TCP_NFQ@/$GAME_TCP_NFQ}"
  line="${line//@GAME_UDP_NFQ@/$GAME_UDP_NFQ}"
  eval "NFQWS_EXTRA_ARGS+=($line)"
done < "$CONFIG_FILE"
"$BIN" --qnum=$QNUM "${NFQWS_EXTRA_ARGS[@]}"
