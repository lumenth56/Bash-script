#!/usr/bin/env bash
# Uso: bash pokeinfo.sh <name>
set -euo pipefail

API="https://pokeapi.co/api/v2"

if [ "$#" -lt 1 ]; then
  echo "Uso: $0 <name>" >&2
  exit 1
fi

NAME=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if ! curl -sf "$API/pokemon/$NAME" | tr ',' '\n' > "$TMP/poke"; then
  echo "No se encontro el pokemon: $1" >&2
  exit 1
fi

SPECIES_URL=$(grep -om1 "$API/pokemon-species/[0-9]*/" "$TMP/poke")
curl -sf "$SPECIES_URL" | tr ',' '\n' > "$TMP/spec"

grep -om1 '"species":{"name":"[^"]*"' "$TMP/poke" \
  | sed 's/.*:"/Name: /; s/"$//'

LINE=$(grep -n '"types":\[' "$TMP/poke" | tail -n1 | cut -d: -f1)
tail -n "+$LINE" "$TMP/poke" | grep -o '"type":{"name":"[^"]*"' \
  | sed 's/.*:"/Type: /; s/"$//'

grep -om1 '"weight":[0-9]*' "$TMP/poke" \
  | sed 's/"weight"://; s/^/Weight: /'

grep -om1 '"color":{"name":"[^"]*"' "$TMP/spec" \
  | sed 's/.*:"/Color: /; s/"$//'