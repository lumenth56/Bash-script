#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Uso: $0 <nombre-pokemon>"
    exit 1
fi

NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')

RESPONSE=$(curl -s -w "\n%{http_code}" \
    "https://pokeapi.co/api/v2/pokemon/$NAME")

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

DATA=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 404 ]; then
    echo "El pokemón no existe o no fue encontrado"
    exit 1
fi

if [ "$HTTP_CODE" -ne 200 ]; then
    echo "Error al consultar la PokeAPI"
    exit 1
fi

ID=$(echo "$DATA" | jq -r '.id')
POKEMON_NAME=$(echo "$DATA" | jq -r '.name')
HEIGHT=$(echo "$DATA" | jq -r '.height')

echo "Id: $ID Name:$POKEMON_NAME Height: $HEIGHT"

