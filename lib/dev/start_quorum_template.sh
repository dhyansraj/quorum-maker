#!/bin/bash

function upcheck() {
    DOWN=true
    k=10
    while ${DOWN}; do
        sleep 1
        DOWN=false
        
        if [ ! -S "qdata/#mNode#.ipc" ]; then
            echo "Node is not yet listening on #mNode#.ipc" >> qdata/gethLogs/#mNode#.log
            DOWN=true
        fi

        result=$(curl -s http://$CURRENT_NODE_IP:22002/upcheck)

        if [ ! "${result}" == "I'm up!" ]; then
            echo "Node is not yet listening on http" >> qdata/gethLogs/#mNode#.log
            DOWN=true
        fi
    
        k=$((k - 1))
        if [ ${k} -le 0 ]; then
            echo "Tessera is taking a long time to start.  Look at the Tessera logs for help diagnosing the problem." >> qdata/gethLogs/#mNode#.log
        fi
       
        sleep 5
    done
}

NETID=#network_Id_value#
RA_PORT=22003
R_PORT=22000
W_PORT=22001
NODE_MANAGER_PORT=22004
WS_PORT=22005
CURRENT_NODE_IP=#node_ip#

tessera="java -jar /tessera/tessera-app.jar"

ENABLED_API="admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft"
GLOBAL_ARGS="--raft --nodiscover --gcmode=archive --networkid $NETID --rpc --rpcaddr 0.0.0.0 --rpcapi $ENABLED_API --emitcheckpoints --allow-insecure-unlock"

rm -f qdata/*lock.db


rm -f /${NODE_NAME}/node/qdata/${NODE_NAME}.ipc

echo "[*] Starting Tessera node" > qdata/tesseraLogs/tessera_#mNode#.log

$tessera -configfile tessera-config.json >> qdata/tesseraLogs/tessera_${NODENAME}.log 2>&1 &

upcheck

echo "[*] Starting #mNode# node" > qdata/gethLogs/#mNode#.log

echo "[*] Waiting for Tessera to start..." >> qdata/gethLogs/#mNode#.log

upcheck

echo "[*] Starting #mNode# node" >> qdata/gethLogs/#mNode#.log
echo "[*] geth --verbosity 6 --datadir qdata" $GLOBAL_ARGS" --raftport $RA_PORT --rpcport "$R_PORT "--port "$W_PORT "--nat extip:"$CURRENT_NODE_IP>> qdata/gethLogs/#mNode#.log

PRIVATE_CONFIG=qdata/#mNode#.ipc geth --verbosity 6 --datadir qdata $GLOBAL_ARGS --rpccorsdomain "*" --raftport $RA_PORT --rpcport $R_PORT --port $W_PORT --ws --wsaddr 0.0.0.0 --wsport $WS_PORT --wsorigins '*' --wsapi $ENABLED_API --nat extip:$CURRENT_NODE_IP 2>>qdata/gethLogs/#mNode#.log &

