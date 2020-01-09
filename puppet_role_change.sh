#!/bin/bash
#set -x
export TMPSH="/tmp/tpup.sh"
export TMPEXP="/tmp/tpup.expect"
export TMPOP="/tmp/op"
rm ${TMPEXP} ${TMPOP} ${TMPSH} &>/dev/null

tmp_rolecheck() {
echo '#!/usr/bin/expect'      > ${TMPEXP}
echo "spawn ${TMPSH}"         >> ${TMPEXP}
echo 'expect "q)uit > "'      >> ${TMPEXP}
echo 'send "exit\r"'          >> ${TMPEXP}
chmod 777 ${TMPEXP}
}

tmp_roleexist() {
echo '#!/usr/bin/expect'      > ${TMPEXP}
echo "spawn ${TMPSH}"         >> ${TMPEXP}
echo 'expect "q)uit > "'      >> ${TMPEXP}
echo 'send "3\r"'             >> ${TMPEXP}
echo 'expect {'               >> ${TMPEXP}
echo ' "Continue: " {'        >> ${TMPEXP}
echo '        send "\r"'      >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo ' "choice : " {'         >> ${TMPEXP}
echo '        send "95\r"'    >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo '}'                      >> ${TMPEXP}
echo 'expect {'               >> ${TMPEXP}
echo ' "Continue: " {'        >> ${TMPEXP}
echo '        send "\r"'      >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo ' "choice : " {'         >> ${TMPEXP}
echo '        send "95\r"'    >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo '}'                      >> ${TMPEXP}
echo 'send "exit\r"'          >> ${TMPEXP}
chmod 777 ${TMPEXP}
}

tmp_rolechange() {
echo '#!/usr/bin/expect'      > ${TMPEXP}
echo "spawn ${TMPSH}"         >> ${TMPEXP}
echo 'expect "q)uit > "'      >> ${TMPEXP}
echo 'send "3\r"'             >> ${TMPEXP}
echo 'expect {'               >> ${TMPEXP}
echo ' "Continue: " {'        >> ${TMPEXP}
echo '    send "\r"'          >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo ' "choice : " {'         >> ${TMPEXP}
echo "    send \"$1\r\""      >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo '}'                      >> ${TMPEXP}
echo 'expect {'               >> ${TMPEXP}
echo ' "choice : " {'         >> ${TMPEXP}
echo "    send \"$1\r\""      >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo ' "abort... " {'         >> ${TMPEXP}
echo "    send "Y\r""         >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo '}'                      >> ${TMPEXP}
echo 'expect "abort... "'     >> ${TMPEXP}
echo 'send "Y\r"'             >> ${TMPEXP}
echo 'expect eof'             >> ${TMPEXP}
echo 'send "exit\r"'          >> ${TMPEXP}
chmod 777 ${TMPEXP}
}

if [[ $# -eq 2 ]]; then
  export PSERVER=$1
  export PROLE=$2
  echo "sudo puputil $PSERVER"  > ${TMPSH}
  chmod 777 ${TMPSH}            2>/dev/null

  #OLD role vs NEW role check for change
  tmp_rolecheck
  /usr/bin/expect ${TMPEXP} > ${TMPOP} 2>/dev/null
  OPROLE=$(cat ${TMPOP} | head -8 | grep -w "Agent" | awk '{print $(NF-1)}')
  if [[ -z $(cat ${TMPOP} | grep -w "$PROLE") ]]; then
        echo -e "\nExisting role -> \"$OPROLE\" is different from new \"$PROLE\""
    echo -e "\nProceeding with role change..."; sleep 1
  else
    echo -e "\n\n\"$PSERVER\" is already assigned with \"$PROLE\" role..\n\n  NO ROLE changes.\n"
        sleep 1
        exit 20
  fi

  #check for NEW role existance
  tmp_roleexist
  /usr/bin/expect ${TMPEXP} > ${TMPOP} 2>/dev/null
  if [[ ! -z $(cat ${TMPOP} | grep -w "$PROLE") ]]; then
    PROLENUM=$(cat ${TMPOP} | grep -w "$PROLE" | awk -F "$PROLE" '{print $1}' | awk '{print $NF}')
  else
    echo -e "\nNO SUCH ROLE.....  Exiting now.\n\n"
        sleep 1
    exit 22
  fi

  #applying new role
  tmp_rolechange $PROLENUM
  #/usr/bin/expect ${TMPEXP} > ${TMPOP} 2>/dev/null
  /usr/bin/expect ${TMPEXP} 2>/dev/null

  #validating new role
  tmp_rolecheck
  /usr/bin/expect ${TMPEXP} > ${TMPOP} 2>/dev/null
  if [[ ! -z $(cat ${TMPOP} | grep -w "$PROLE") ]]; then
    echo -e "\n\nDone..."
    echo -e "Role chnaged to $PROLE for $PSERVER ...\n\n"
  else
    echo -e "Unable to change role... Please re-run"
  fi
else
  echo -e "\n\nPlease run as: \"$0 Server PuppetRole\"\n"
  echo -e "       Server: On which you wanted role change"
  echo -e "   PuppetRole: new role wanted to apply\n\n"
fi
rm ${TMPEXP} ${TMPOP} ${TMPSH} &>/dev/null
