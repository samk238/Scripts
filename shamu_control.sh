#!/bin/bash
#set -x
export TMPSH="/tmp/tshamu.sh"
export TMPEXP="/tmp/tshamu.expect"
export TMPOP="/tmp/shamuop"
rm ${TMPEXP} ${TMPOP} ${TMPSH} &>/dev/null

#select env
#
tmp_serverctrl() {
echo '#!/usr/bin/expect'      > ${TMPEXP}
echo "spawn ${TMPSH}"         >> ${TMPEXP}
echo 'expect "Quit : "'       >> ${TMPEXP}
echo "send \"$2\r\""          >> ${TMPEXP}
echo 'expect {'               >> ${TMPEXP}
echo ' "Continue: " {'        >> ${TMPEXP}
echo '    send "\r"'          >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo ' "Quit): " {'           >> ${TMPEXP}
if [[ $1 == servercheck ]]; then
echo 'send "exit\r"'          >> ${TMPEXP}
echo 'send "exit\r"'          >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo '}'                      >> ${TMPEXP}
echo 'expect {'               >> ${TMPEXP}
echo ' "Continue: " {'        >> ${TMPEXP}
echo '    send "\r"'          >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo ' "Quit): " {'           >> ${TMPEXP}
echo 'send "exit\r"'          >> ${TMPEXP}
echo 'send "exit\r"'          >> ${TMPEXP}
echo ' }'                     >> ${TMPEXP}
echo '}'                      >> ${TMPEXP}
fi
if [[ $1 == serveraction ]]; then
  echo "    send \"$3\r\""      >> ${TMPEXP}
  echo ' }'                     >> ${TMPEXP}
  echo '}'                      >> ${TMPEXP}
  echo 'expect {'               >> ${TMPEXP}
  echo ' "Continue: " {'        >> ${TMPEXP}
  echo '    send "\r"'          >> ${TMPEXP}
  echo ' }'                     >> ${TMPEXP}
  echo ' "Quit): " {'           >> ${TMPEXP}
  echo "    send \"$3\r\""      >> ${TMPEXP}
  echo ' }'                     >> ${TMPEXP}
  echo '}'                      >> ${TMPEXP}
  echo 'expect {'               >> ${TMPEXP}
  echo ' "Continue: " {'        >> ${TMPEXP}
  echo '    send "\r"'          >> ${TMPEXP}
  echo ' }'                     >> ${TMPEXP}
  echo ' "Quit): " {'           >> ${TMPEXP}
  echo "    send \"$3\r\""      >> ${TMPEXP}
  echo ' }'                     >> ${TMPEXP}
  echo '}'                      >> ${TMPEXP}
if [[ $4 != "sd" ]]; then
  echo 'expect "Quit : "'       >> ${TMPEXP}
  echo "send \"$4\r\""          >> ${TMPEXP}
  echo 'expect "continue. "'    >> ${TMPEXP}
  echo 'send "exit\r"'          >> ${TMPEXP}
elif [[ $4 == "sd" ]]; then
  for j in $(cat upservers_num); do
    echo 'expect "Quit : "'       >> ${TMPEXP}
    echo "send \"$j\r\""          >> ${TMPEXP}
    echo 'expect "Quit : "'       >> ${TMPEXP}
    echo "send \"u\r\""           >> ${TMPEXP}
    echo 'expect "continue "'     >> ${TMPEXP}
    echo 'send "\r"'              >> ${TMPEXP}
  done
fi
fi
chmod 777 ${TMPEXP}
}

if [[ $# -eq 3 ]]; then
  export ENV=$1
  export SERVER=$2
  export ACTION=$3
  echo "shamu_menu"  > ${TMPSH}
  chmod 777 ${TMPSH} 2>/dev/null
  if [[ $ENV == prd ]]; then OPTION1=1
  elif [[ $ENV == prf ]]; then  OPTION1=2
  elif [[ $ENV == trn ]]; then OPTION1=3
  elif [[ $ENV == sys ]]; then OPTION1=4
  elif [[ $ENV == uat ]]; then OPTION1=5
  elif [[ $ENV == unt ]]; then OPTION1=6
  elif [[ $ENV == dev ]]; then OPTION1=7
  elif [[ $ENV == lab ]]; then OPTION1=8
  elif [[ $ENV == sup ]]; then OPTION1=9
  elif [[ $ENV == fit ]]; then OPTION1=10
  elif [[ $ENV == tst ]]; then OPTION1=11
  else
	echo -e "\n\nPlease select appropriate env: prd, prf, trn, sys, uat, unt, dev, lab, sup, fit, tst ..."
	exit 22
  fi
  
  #server check
  tmp_serverctrl servercheck $OPTION1
  /usr/bin/expect ${TMPEXP} > ${TMPOP} 2>/dev/null
  if [[ ! -z $(cat ${TMPOP} | grep -w "$SERVER") ]]; then
    OPTION2=$(cat ${TMPOP} | grep -w "$SERVER" | awk -F "$SERVER" '{print $1}' | awk '{print $NF}')
	echo -e "\nServer \"$SERVER\" found under \"$ENV\"...."
	echo -e "Sending server number \"$OPTION2\" along with \"$ACTION\" action...."
  else
    echo -e "\nNO SUCH SERVER $SERVER.....  Exiting now.\n\n"
    exit 22
  fi
  
  #slecting server and send Action
  if [[ $ACTION == UpAll ]]; then OPTION3=u
  elif [[ $ACTION == DownAll ]]; then  OPTION3=d
  elif [[ $ACTION == StatusAll ]]; then OPTION3=s
  elif [[ $ACTION == SAMESTATERESTARTS ]]; then OPTION3=sd
  else
	echo -e "\n\nPlease select appropriate action: UpAll, DownAll, StatusAll ..."
	exit 22
  fi
  if [[ $OPTION3 != sd ]]; then
    tmp_serverctrl serveraction $OPTION1 $OPTION2 $OPTION3
    /usr/bin/expect ${TMPEXP} > ${TMPOP} 2>/dev/null
    cat ${TMPOP}
  elif [[ $OPTION3 == sd ]]; then
    tmp_serverctrl serveraction $OPTION1 $OPTION2 s
	/usr/bin/expect ${TMPEXP} > status.txt 2>/dev/null
    cat status.txt
    cat status.txt | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" > status1.txt
    #rm status.txt
    cat status1.txt | grep -w "UP" | awk -F "UP" '{print $1}' | awk '{$1=$1;print}' > upservers
    cat status1.txt | grep -w "DOWN" | awk -F "DOWN" '{print $1}' | awk '{$1=$1;print}' > downservers
    for iu in $(cat upservers); do cat status1.txt | grep -w $iu | grep -v "UP\|DOWN" ; done | awk '{print $1}' | cut -d. -f1 > upservers_num
    for id in $(cat downservers); do cat status1.txt | grep -w $id | grep -v "UP\|DOWN" ; done | awk '{print $1}' | cut -d. -f1 > downservers_num
	tmp_serverctrl serveraction $OPTION1 $OPTION2 sd
  fi
else
  echo -e "\n\nPlease run as: \"$0 ENV SERVER ACTION\"\n"
  echo -e "     ENV: prd, prf, trn, sys, uat, unt, dev, lab, sup, fit, tst"
  echo -e "  SERVER: Hostname"
  echo -e "  ACTION: UpAll, DownAll, StatusAll\n\n"
fi
#rm ${TMPEXP} ${TMPOP} ${TMPSH} &>/dev/null