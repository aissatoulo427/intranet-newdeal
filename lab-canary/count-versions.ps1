# Compte la repartition du trafic entre v1 et v2 a travers le Service.
#
# Sur ce Docker Desktop (Kubernetes type "kind"), les NodePort ne sortent pas
# sur localhost. On mesure donc la repartition DEPUIS l'interieur du cluster :
# un pod busybox interroge N fois le Service ClusterIP (DNS interne), la ou
# kube-proxy load-balance reellement entre les pods v1 et v2.
#
# Marqueur cherche : "canary-banner" (id du bandeau, present UNIQUEMENT dans la v2,
# sans espace ni guillemet -> pas de souci d'echappement PowerShell/kubectl).
#
# Usage :   .\count-versions.ps1            (50 requetes par defaut)
#           .\count-versions.ps1 -N 100     (100 requetes)

param(
    [int]$N = 50
)

# Chaine en QUOTES SIMPLES cote PowerShell + AUCUN guillemet double a l'interieur
# => rien n'est interprete/mal echappe, tout part intact au shell busybox.
$sh = 'n=' + $N + '; v2=0; i=0; while [ $i -lt $n ]; do if wget -q -O - http://intranet.lab-canary.svc.cluster.local | grep -q canary-banner; then v2=$((v2+1)); fi; i=$((i+1)); done; echo RESULT v1=$((n-v2)) v2=$v2 sur $n requetes'

kubectl run canary-count --rm -i --restart=Never -n lab-canary `
  --image=busybox:1.28 --command -- sh -c $sh
