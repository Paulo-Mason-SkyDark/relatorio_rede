# Pequeno Gerador de Relatório da Rede (CSV)

## by huddioli feito uma versão#
## 2016-10-22
## refeitar por @SkyDark
## 2021-10-26
 Testado com Linux Debian 8, nmap 6.47, ARPing 2.14 e nmblookup 4.2.10

 Deixei os scans das portas (apenas das TCP padrão) sendo realizados em
 paralelo levando em consideração o tamanho e as características da rede
 (pequena). Caso vá utilizar em uma rede maior, o ruído vai ser enorme e ainda
 corre o risco de não funcionar corretamente dependendo das capacidades da
 interface e da sua rede, mecanismo de segurança...

# Esterei implementando:

        # TO_DO: Controle de scan linear
        # TO_DO: Checagem das permissões do usuário
        # TO_DO: Logs