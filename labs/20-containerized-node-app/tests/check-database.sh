#!/usr/bin/env bash
# Verifie l'application avec sa vraie base PostgreSQL :
#   1. la page / affiche une citation de depart (venant de db/init.sql)
#   2. on ajoute une citation avec un texte unique via POST /quotes
#   3. la page / et /api/quotes contiennent ce texte
# Utilisation : ./tests/check-database.sh   (BASE_URL=http://localhost:3000 par defaut)
set -euo pipefail

URL="${BASE_URL:-http://localhost:3000}"
CITATION_DEPART="Talk is cheap. Show me the code."
MARQUEUR="ci-$(date +%s)"

echo "1) Attente de la citation de depart (30 essais maximum)..."
trouve=0
for essai in $(seq 1 30); do
  page=$(curl --silent --connect-timeout 1 --max-time 2 "$URL/" || true)
  if grep -qF "$CITATION_DEPART" <<< "$page"; then
    trouve=1
    break
  fi
  sleep 1
done
if [ "$trouve" -ne 1 ]; then
  echo "ERREUR : la citation de depart est absente de la page /"
  exit 1
fi
echo "   citation de depart trouvee"

echo "2) Ajout de la citation $MARQUEUR..."
curl --fail --silent --show-error -o /dev/null \
  -d "author=ci&text=$MARQUEUR" "$URL/quotes"

echo "3) La citation est-elle relue depuis la base ?"
page=$(curl --fail --silent --show-error "$URL/")
if ! grep -qF "$MARQUEUR" <<< "$page"; then
  echo "ERREUR : $MARQUEUR est absent de la page /"
  exit 1
fi
json=$(curl --fail --silent --show-error "$URL/api/quotes")
if ! grep -qF "$MARQUEUR" <<< "$json"; then
  echo "ERREUR : $MARQUEUR est absent de /api/quotes"
  exit 1
fi

echo "OK : la citation de depart et la citation ajoutee sont bien dans la base."
