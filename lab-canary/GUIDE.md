# Chapitre 2 — Canary Release sur Kubernetes

Méthode : Kubernetes natif (1 Service, 2 Deployments, ratio de pods).
Cluster : docker-desktop · Namespace : `lab-canary`

> Exécute les commandes depuis PowerShell, dans le dossier `lab-canary/`.

---

## 1) Construire et pousser l'image v2

L'image v2 repart de ta v1 et change juste `index.html` (bandeau « VERSION 2 »).

```powershell
cd C:\Users\HP\Documents\DITI4\cloud\intranet-newdeal\lab-canary\v2
docker build -t aichalo/intranet-newdeal:2.0 .
docker push aichalo/intranet-newdeal:2.0
```

## 2) Créer le namespace et déployer

```powershell
cd C:\Users\HP\Documents\DITI4\cloud\intranet-newdeal\lab-canary
kubectl create ns lab-canary

kubectl apply -f deploy-v1.yaml
kubectl apply -f deploy-v2.yaml
kubectl apply -f service.yaml

kubectl get pods -n lab-canary
```
> Au départ : 4 pods `intranet-v1` (Running) et 0 pod v2 → **100 % v1**.

## 3) Exposer le service (terminal dédié, laisser tourner)

```powershell
kubectl port-forward svc/intranet 8090:80 -n lab-canary
```
Ouvre http://localhost:8090 dans le navigateur.

---

## 4) Dérouler la progression du canary

Pour chaque palier : on ajuste les replicas, on rafraîchit le navigateur (F5) et on lance
le comptage `.\count-versions.ps1`.

### Palier 0 — 100 % v1 (état initial)
```powershell
# v1=4, v2=0  (déjà en place)
.\count-versions.ps1
```
Attendu : v1=100 %, v2=0 %.

### Palier 1 — Canary ~20 %
```powershell
kubectl scale deploy/intranet-v2 -n lab-canary --replicas=1
kubectl get pods -n lab-canary       # attendre que le pod v2 soit Running
.\count-versions.ps1
```
Attendu : ~80 % v1 / ~20 % v2 (1 pod v2 sur 5).
Rafraîchis le navigateur plusieurs fois → tu verras parfois la v2.

### Palier 2 — 50 / 50
```powershell
kubectl scale deploy/intranet-v1 -n lab-canary --replicas=2
kubectl scale deploy/intranet-v2 -n lab-canary --replicas=2
kubectl get pods -n lab-canary
.\count-versions.ps1
```
Attendu : ~50 % / ~50 %.

### Palier 3 — Bascule 100 % v2
```powershell
kubectl scale deploy/intranet-v1 -n lab-canary --replicas=0
kubectl scale deploy/intranet-v2 -n lab-canary --replicas=4
kubectl get pods -n lab-canary
.\count-versions.ps1
```
Attendu : 0 % v1 / 100 % v2. Le navigateur affiche toujours la v2.

---

## 5) (Bonus) Rollback instantané

Si la v2 posait problème, on revient à 100 % v1 en une commande :
```powershell
kubectl scale deploy/intranet-v1 -n lab-canary --replicas=4
kubectl scale deploy/intranet-v2 -n lab-canary --replicas=0
```

## 6) Nettoyage

```powershell
kubectl delete namespace lab-canary
```

---

## Captures d'écran à prendre (pour le rapport)
- `c2-01-browser-v1.png` : le site en v1 (bandeau normal)
- `c2-02-browser-v2.png` : le site en v2 (bandeau rouge « VERSION 2 »)
- `c2-03-count-20.png` : comptage au palier 20 %
- `c2-04-count-50.png` : comptage au palier 50 %
- `c2-05-count-100.png` : comptage au palier 100 %
- `c2-06-pods.png` : `kubectl get pods -n lab-canary` montrant les 2 versions

## Principe (rappel)
Le Service `intranet` sélectionne uniquement `app: intranet`. Comme les pods v1 **et** v2
portent ce label, le Service répartit le trafic sur les deux → le pourcentage de trafic
vers v2 est piloté par le **nombre de pods** de chaque version.
