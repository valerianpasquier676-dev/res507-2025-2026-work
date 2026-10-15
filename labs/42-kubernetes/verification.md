# TP 42 - Vérification

## Environnement
- Ubuntu 26.04.1 LTS, k3s v1.36.5+k3s1, runtime containerd://2.3.4-k3s1.36, noeud devops-vm Ready
- Image docker.io/library/quote-app:local présente dans k3s

## /health et Service
- Service : quote-app ClusterIP 10.43.211.240 80/TCP
- port-forward : {"ok":true}
- depuis le cluster (pod service-check) : wget http://quote-app/health -> {"ok":true}

## 3 réplicas
quote-app-69fbbcff49-hm7bl 1/1, quote-app-69fbbcff49-lsd8f 1/1, quote-app-69fbbcff49-v99wf 1/1

## Remplacement d'un pod
- supprimé : quote-app-69fbbcff49-hm7bl
- remplaçant : quote-app-69fbbcff49-2s6ht (1/1)
Le ReplicaSet recrée un pod avec un nouveau nom pour garder 3 réplicas.

## Échec volontaire de la readiness
Chemin de la sonde changé : /health -> /does-not-exist
- rollout status : error: timed out waiting for the condition
- nouveau pod : quote-app-57b88c776b-6dpdf 0/1 Running, RESTARTS 0
- ReplicaSets : quote-app-69fbbcff49 3/3/3, quote-app-57b88c776b 1/1/0
- événement : Warning Unhealthy ... Readiness probe failed: HTTP probe failed with statuscode: 404
- EndpointSlice : le nouveau pod ready=false, les 3 anciens ready=true

Symptôme : le nouveau pod reste 0/1 et le déploiement ne se termine pas, mais le service répond encore.
Cause : la sonde interroge /does-not-exist, qui renvoie 404, donc le pod n'est jamais prêt et ne reçoit pas de trafic.
Solution : remettre /health. La sonde est conservée, pas supprimée, sinon le pod serait prêt sans vérification.

## Récupération
rollout status : successfully rolled out, 3 pods 1/1, et http://quote-app/health répond {"ok":true}.

## Extension : sonde de vivacité (liveness)
Ajout d'une livenessProbe sur /health, puis chemin cassé en /does-not-exist.
- événement : Normal Killing ... Container quote-app failed liveness probe, will be restarted
- RESTARTS monte jusqu'à 4, avec CrashLoopBackOff
- après restauration de /health : 3 pods 1/1, RESTARTS 0
La readiness retire le pod du trafic sans le redémarrer. La liveness redémarre le conteneur.

## Limites
/health ne vérifie pas PostgreSQL : rien ici ne prouve que la base fonctionne.
Un seul nœud : 3 réplicas ne protègent pas contre la perte de la VM.
