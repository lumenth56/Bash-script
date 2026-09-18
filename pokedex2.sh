#!/bin/bash
# Uso: ./pokemon.sh <nombre|id>
# Ejemplo: ./pokemon.sh pikachu
# Requiere: curl y jq

set -uo pipefail

BASE_URL="https://pokeapi.co/api/v2"

# --- Validaciones ---------------------------------------------------------
if [[ $# -ne 1 || -z "${1// /}" ]]; then
  echo "Uso: $0 <nombre|id>" >&2
  exit 2
fi

for cmd in curl jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: se requiere '$cmd' instalado." >&2
    exit 2
  fi
done

# La API espera el nombre en minúsculas
query=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

# --- Función de consulta --------------------------------------------------
# Devuelve el cuerpo en $BODY y el código HTTP en $HTTP_CODE
fetch() {
  local resp
  if ! resp=$(curl -sS --max-time 15 -w $'\n%{http_code}' "$1"); then
    echo "Error de red al consultar la API." >&2
    exit 2
  fi
  HTTP_CODE="${resp##*$'\n'}"
  BODY="${resp%$'\n'*}"
}

# --- 1) pokemon-species: id, name, habitat, color -------------------------
fetch "$BASE_URL/pokemon-species/$query"

if [[ "$HTTP_CODE" == "404" ]]; then
  echo "No encontrado"
  exit 1
elif [[ "$HTTP_CODE" != "200" ]]; then
  echo "Error: la API respondió HTTP $HTTP_CODE" >&2
  exit 2
fi

IFS=$'\t' read -r id name habitat color < <(
  jq -r '[.id, .name, (.habitat.name // "desconocido"), .color.name] | @tsv' <<<"$BODY"
)

# --- 2) pokemon: type (no viene en pokemon-species) -----------------------
fetch "$BASE_URL/pokemon/$id"

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "Error: no se pudo obtener el tipo (HTTP $HTTP_CODE)" >&2
  exit 2
fi

type=$(jq -r '[.types[].type.name] | join(",")' <<<"$BODY")

# --- Salida ---------------------------------------------------------------
echo "id:$id name:$name habitat:$habitat type:$type color:$color"

