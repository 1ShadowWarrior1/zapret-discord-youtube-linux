if [ "$EUID" -ne 0 ]; then
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

FAKE="$WORK_DIR/zapret/files/fake"

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

echo "=> Запуск nfqws..."
"$BIN" --qnum=$QNUM \
--filter-udp=443 --hostlist="$LISTS_DIR/list-general.txt" --hostlist-exclude="$LISTS_DIR/list-exclude.txt" --ipset-exclude="$LISTS_DIR/ipset-exclude.txt" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic="$FAKE/quic_initial_www_google_com.bin" --new \
--filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=6 --new \
--filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=ts --dpi-desync-repeats=8 --dpi-desync-split-seqovl-pattern="$FAKE/tls_clienthello_www_google_com.bin" --dpi-desync-fake-tls="$FAKE/tls_clienthello_www_google_com.bin" --new \
--filter-tcp=443 --hostlist="$LISTS_DIR/list-google.txt" --ip-id=zero --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=ts --dpi-desync-repeats=8 --dpi-desync-split-seqovl-pattern="$FAKE/tls_clienthello_www_google_com.bin" --dpi-desync-fake-tls="$FAKE/tls_clienthello_www_google_com.bin" --new \
--filter-tcp=80,443 --hostlist="$LISTS_DIR/list-general.txt" --hostlist-exclude="$LISTS_DIR/list-exclude.txt" --ipset-exclude="$LISTS_DIR/ipset-exclude.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=664 --dpi-desync-split-pos=1 --dpi-desync-fooling=ts --dpi-desync-repeats=8 --dpi-desync-split-seqovl-pattern="$FAKE/tls_clienthello_www_google_com.bin" --dpi-desync-fake-tls="$FAKE/tls_clienthello_www_google_com.bin" --new \
--filter-udp=443 --ipset="$LISTS_DIR/ipset-all.txt" --hostlist-exclude="$LISTS_DIR/list-exclude.txt" --ipset-exclude="$LISTS_DIR/ipset-exclude.txt" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic="$FAKE/quic_initial_www_google_com.bin" --new \
--filter-tcp=80,443,$GAME_TCP_NFQ --ipset="$LISTS_DIR/ipset-all.txt" --hostlist-exclude="$LISTS_DIR/list-exclude.txt" --ipset-exclude="$LISTS_DIR/ipset-exclude.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=664 --dpi-desync-split-pos=1 --dpi-desync-fooling=ts --dpi-desync-repeats=8 --dpi-desync-split-seqovl-pattern="$FAKE/tls_clienthello_www_google_com.bin" --dpi-desync-fake-tls="$FAKE/tls_clienthello_www_google_com.bin" --new \
--filter-udp=$GAME_UDP_NFQ --ipset="$LISTS_DIR/ipset-all.txt" --ipset-exclude="$LISTS_DIR/ipset-exclude.txt" --dpi-desync=fake --dpi-desync-repeats=10 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="$FAKE/quic_initial_www_google_com.bin" --dpi-desync-cutoff=n4