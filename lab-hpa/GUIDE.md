# Lab — Test d'Autoscaling (HPA) sur Kubernetes

Cluster : **docker-desktop** · Image de l'app : `aichalo/intranet-newdeal:latest` (port 80)

> Exécute les commandes dans PowerShell depuis le dossier `lab-hpa/`.
> Corrections apportées par rapport au PDF : voir les notes ⚠️.

---

## 1) Créer le namespace

```powershell
kubectl create ns lab-hpa
```

## 2) & 3) Déployer l'application (avec requests/limits déjà inclus)

```powershell
kubectl apply -f deploy-lab-hpa.yaml
kubectl apply -f service.yaml
kubectl get pods -n lab-hpa
```

⚠️ Le YAML du PDF (format `apiVersion: v1 / items:`) était mal indenté et n'a pas de Service.
Ici c'est un `Deployment` propre + un `Service` (indispensable pour K6, étape 8).

## 4) Stack Observabilité (Prometheus + Grafana + Loki)

```powershell
kubectl create namespace observability

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack -n observability

kubectl get pods -n observability
kubectl get svc -n observability
```

Accès à Grafana (laisser tourner dans un terminal dédié) :

```powershell
kubectl port-forward svc/monitoring-grafana 8085:80 -n observability
```

Mot de passe admin Grafana (user = `admin`) :

```powershell
kubectl get secret monitoring-grafana -n observability -o jsonpath="{.data.admin-password}" | base64 --decode
```

Loki :

```powershell
helm install loki grafana/loki-stack -n observability
kubectl get pods -n observability
# Accès optionnel (⚠️ PDF disait -n monitoring, c'est -n observability) :
kubectl port-forward svc/loki 8031:3100 -n observability
```

## 5) metrics-server (OBLIGATOIRE pour le HPA)

⚠️ L'URL du PDF (`https://github.io`) est fausse. Bonne URL + flag TLS en une commande :

```powershell
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm install metrics-server metrics-server/metrics-server -n kube-system --set "args={--kubelet-insecure-tls}"
```

Vérification (attends ~1 min que ça devienne Running) :

```powershell
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server
kubectl top nodes
kubectl top pods -n lab-hpa
```

> `kubectl top` doit renvoyer des chiffres. Sinon le HPA affichera `<unknown>`.

## 6) ResourceQuota

```powershell
kubectl apply -f quota-app.yaml
kubectl get resourcequota -n lab-hpa
```

## 7) Déployer le HPA

```powershell
kubectl apply -f hpa.yaml
kubectl get hpa -n lab-hpa -w
```

⚠️ Ajout de `namespace: lab-hpa` dans le HPA (absent du PDF).
Laisse `-w` tourner : tu verras les TARGETS (%) et REPLICAS évoluer pendant les tests.

## 8) Tests de charge avec K6

D'abord, exposer l'app sur le port **8087** (dans un terminal dédié, à laisser ouvert) :

```powershell
kubectl port-forward svc/webapp 8087:80 -n lab-hpa
```

Puis, depuis le dossier `lab-hpa/k6/` :

**Scénario 1 — charge constante (1000 VUs, 6 min)**
```powershell
docker run --rm -i grafana/k6 run - < script.js
```

**Scénario 2 — ramp up/down**
```powershell
docker run --rm -i grafana/k6 run - < ramp-up-down.js
```

Pendant les tests, observe l'autoscaling dans un autre terminal :
```powershell
kubectl get hpa -n lab-hpa -w
kubectl get pods -n lab-hpa -w
```
→ Le nombre de pods doit monter (jusqu'à 10) puis redescendre vers 1.

**Scénario 3 (optionnel)** — nécessite le k6-operator :
```powershell
kubectl create configmap k6-test --from-file=script.js -n lab-hpa
kubectl apply -f k6-test-run.yaml
```

## 9) Nettoyage

```powershell
helm uninstall monitoring -n observability
helm uninstall loki -n observability
kubectl delete namespace observability
kubectl delete namespace lab-hpa
helm uninstall metrics-server -n kube-system
```

---

### Récap des corrections vs PDF
1. Deployment reformaté proprement + image `aichalo/intranet-newdeal:latest`.
2. Ajout d'un **Service** `webapp` (manquant, requis pour le port-forward 8087).
3. metrics-server : URL corrigée `https://kubernetes-sigs.github.io/metrics-server/` + `--kubelet-insecure-tls`.
4. Loki port-forward : `-n observability` (au lieu de `-n monitoring`).
5. HPA : ajout de `namespace: lab-hpa`.
