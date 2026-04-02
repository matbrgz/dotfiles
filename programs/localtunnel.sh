#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
    set +e
else
    set -e
fi
npm install -g localtunnel

echo "
#!/bin/bash

### BEGIN INIT INFO
# Provides:             localtunnel
# Required-Start:       $network
# Required-Stop:        $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    O Meu Serviço
# Description:          Uma descricao mais completa sobre o meu serviço
### END INIT INFO
# chkconfig: 2345 95 20

start() {
  while true;
    do lt --port 1337 -s betim1;
    sleep 10;
  done
}

stop() {
  echo 'Eu executei stop!' > /var/log/localtunnel.log
}

restart() {
  stop
  start
}

case \"$1\" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    restart
    ;;
  *)
    echo $\"Usage: $0 {start | stop | restart}\"
    exit 1
esac
  
exit $?
" >>/etc/init.d/localtunnel
update-rc.d localtunnel defaults
