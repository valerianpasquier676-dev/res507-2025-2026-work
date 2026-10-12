#!/usr/bin/env bash
# Test simple : on ajoute une citation par le site, puis on verifie
# qu'elle est bien dans la base PostgreSQL, et on montre ou elle est stockee.
# Lancer depuis le dossier labs/20-containerized-node-app :
#   ./tests/verifier-donnees.sh
set -euo pipefail

COMPOSE="docker compose -f docker/compose.yaml"
MARQUEUR="test-$(date +%s)"

echo "1) Demarrage de l'application et de la base..."
$COMPOSE up -d --build
sleep 10

echo "2) Verification de /health..."
curl -sf http://localhost:3000/health
echo

echo "3) Ajout d'une citation via le formulaire ($MARQUEUR)..."
curl -s -o /dev/null -d "author=etudiant&text=$MARQUEUR" http://localhost:3000/quotes

echo "4) La citation est-elle dans la base PostgreSQL ?"
$COMPOSE exec -T db psql -U postgres -d postgres -c "SELECT id, author, text FROM quotes WHERE text = '$MARQUEUR';"

echo "5) Ou sont rangees les donnees ? (volume Docker)"
docker volume inspect docker_pgdata --format 'Volume : {{.Name}} -> {{.Mountpoint}}'

echo "6) Nettoyage de la ligne de test..."
$COMPOSE exec -T db psql -U postgres -d postgres -c "DELETE FROM quotes WHERE text = '$MARQUEUR';"

echo "OK : test termine."
