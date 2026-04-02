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

loopFunction(bool) {
  while true; do
    if [ \"${bool}\" == false ]; then
      break
    fi
    lt --port 2200 -s matheusrv;
    sleep 10;
  done
}

start() {
  loopFunction true
}

stop() {
  loopFunction false
  exit 1
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