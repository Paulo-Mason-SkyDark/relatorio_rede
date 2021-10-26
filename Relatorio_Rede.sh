#!/bin/bash

REDE="10.5.1.0/24"
NOME_BASE="rede"
INTERFACE="eth0"
IP_INTERFACE=$(ifconfig $INTERFACE | grep 'inet addr' | cut -d: -f2 | cut -d' ' -f1)

AGORA=$(date +%Y-%m-%d-%H:%M:%S)

DIRETORIO="scan_targets"

LISTA_DE_ALVOS=''

RELATORIO_FINAL="Relatorio_""$NOME_BASE"".csv"

VAR_HOSTNAME='NOME_DO_HOST'
VAR_GW='GATEWAY'
SITE='8.8.4.4'

VerificarEstruturas(){

	if [ -e "$DIRETORIO" ]
	  then
	     rm -rf "$DIRETORIO"
	fi

	mkdir "$DIRETORIO"

	if [ -e "$RELATORIO_FINAL" ]
		 then
			 rm -f "$RELATORIO_FINAL"
	fi

}

IdentificarHosts(){

	echo "Scaneando os Hosts ativos da rede $REDE"
	echo "Interface: $INTERFACE"
	echo "Identificando Hosts ativos na Rede..."
  TARGETS=$(echo $(nmap -n -sn -PR $REDE | grep report | cut -d" " -f5)" "$(nmap -n -sn $REDE | grep report | cut -d" " -f5) | tr " " "\n" | sort -u | egrep -v "($(ifconfig | egrep -io '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sort | uniq | xargs | tr ' ' '|'))")

}

ScanearHosts(){
  # Cuidado com a paralelização dos scans realizados!
	for IP_ALVO in $TARGETS
	   do
		echo "IP \"$IP_ALVO\" adicionado"
		nmap -n -sS -O "$IP_ALVO" >> "$DIRETORIO/""$IP_ALVO"".target" &
	        echo "$VAR_HOSTNAME:"$(nmblookup -A "$IP_ALVO" | grep 00 | sed "s/^\t//" | sed -n "1p" | cut -d" " -f1) >> "$DIRETORIO/""$IP_ALVO"".target" &
		echo "$VAR_GW:"$(EncontrarAcessoInternet "$IP_ALVO" 2> /dev/null) >> "$DIRETORIO/""$IP_ALVO"'.target' &
	   done
	wait

}

FiltrarDados(){

	#Monta o cabeçalho do Relatorio CSV
	if [ ! -e "$RELATORIO_FINAL" ]
	   then
	      echo "IP;MAC;FABRICANTE;HOSTNAME;PORTAS(TCP);SO;GATEWAY;DATA" >> "$RELATORIO_FINAL"
	fi

	for IP in $TARGETS
	  do
	     MAC=$(cat "$DIRETORIO/""$IP"".target" | egrep -io "[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}");
	     FABRICANTE=$(cat "$DIRETORIO/""$IP"".target" | grep MAC | egrep -io "\([a-zA-Z,0-9 -._]*\)" | sed -e "{ s/^(//g; s/)$//g }");
	     SO=$(cat "$DIRETORIO/""$IP"".target" | grep Running | cut -d":" -f2 | sed "s/^ //");
	     GATEWAY=$(cat "$DIRETORIO/""$IP"".target" | grep "$VAR_GW" | cut -d":" -f2);
	     NOME_DO_HOST=$(cat "$DIRETORIO/""$IP"".target" | grep "$VAR_HOSTNAME" | cut -d":" -f2);

	     for PORTA in $(cat "$DIRETORIO/""$IP"".target" | grep open | cut -d"/" -f1)
	        do
	           PORTA2+="$PORTA,";
	        done

	     PORTAS=$(echo "$PORTA2" | sed "{ s/,*$//  }")
	     unset PORTA2
	     # Insere os dados do registro
	     echo "$IP;$MAC;$FABRICANTE;$NOME_DO_HOST;$PORTAS;$SO;$GATEWAY;$AGORA" >> "$RELATORIO_FINAL"

	  done

}

EncontrarAcessoInternet(){
		IP_GW="$1"
		MAC_GW=$(arping -i "$INTERFACE" -c 1 "$IP_GW" | egrep -io "[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}")

		if (arping -i "$INTERFACE" -c 3 -S "$IP_INTERFACE" -T "$SITE" "$MAC_GW" > /dev/null 2> /dev/null)
			then
				SAIDA="Sim"
			else
				SAIDA="Não"
		fi
		echo "$SAIDA"
}

LimparCache(){

	rm -rf "$DIRETORIO"

}

Main(){

	echo "Relatorio Final salvo em: $RELATORIO_FINAL"
	VerificarEstruturas && IdentificarHosts && ScanearHosts && FiltrarDados
  LimparCache

}

Main
