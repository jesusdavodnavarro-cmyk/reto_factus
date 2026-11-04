#!/usr/bin/env bash
# Prueba de humo: recorre TODO lo construido hasta ahora, en orden.
# Uso (con `pnpm dev` corriendo en otra terminal):
#   bash scripts/smoke.sh
# Otra URL:  API=http://localhost:3001/api bash scripts/smoke.sh

API="${API:-http://localhost:3000/api}"
FALLOS=0

# Hace la petición y deja el código HTTP en $CODE y el cuerpo en $BODY
req() {
  local method=$1 path=$2 data=${3:-}
  local out
  if [[ -n "$data" ]]; then
    out=$(curl -s -X "$method" "$API$path" -H 'Content-Type: application/json' -d "$data" -w $'\n%{http_code}')
  else
    out=$(curl -s -X "$method" "$API$path" -w $'\n%{http_code}')
  fi
  CODE=${out##*$'\n'}
  BODY=${out%$'\n'*}
}

# Compara el código HTTP con el esperado
check() {
  local nombre=$1 esperado=$2
  if [[ "$CODE" == "$esperado" ]]; then
    echo "✅ $nombre ($CODE)"
  else
    echo "❌ $nombre: esperaba $esperado y llegó $CODE"
    echo "   ${BODY:0:400}"
    FALLOS=$((FALLOS + 1))
  fi
}

# Saca un campo del JSON con node (ya lo tienes instalado)
campo() { node -pe "const o=JSON.parse(require('fs').readFileSync(0,'utf8')); $1" <<< "$BODY" 2>/dev/null; }

echo "Probando $API"
echo "── Servidor"
req GET /health;                    check "Servidor vivo" 200
[[ "$CODE" == "000" ]] && { echo "   ¿Está corriendo pnpm dev en backend/?"; exit 1; }

echo "── Factus"
req GET /factus/status;             check "Login con Factus" 200
req GET /factus/rangos;             check "Rangos de numeración" 200
[[ "$CODE" == "200" ]] && echo "   Rango activo: $(campo 'o.data?.[0] ? o.data[0].id + " " + o.data[0].prefix : "ninguno"')"

echo "── Hito 1: solicitudes"
req POST /solicitudes '{"consumo":{"valor":516500,"unidad":"COP"},"presupuestoCop":8000000,"areaDisponibleM2":40,"contacto":{"nombre":"Ana Pérez","email":"ana@correo.co","telefono":"3001234567"},"facturacion":{"tipoPersona":"natural","tipoDocumento":"CC","nombres":"Ana Pérez","numeroDocumento":"1067123456","direccion":"Calle 30 # 5-20","email":"ana@correo.co","telefono":"3001234567"}}'
check "Crear solicitud" 201
SOL=$(campo 'o.id')
echo "   $SOL -> $(campo 'o.consumoKwhMes') kWh/mes (esperado 500)"

req POST /solicitudes '{"consumo":{"valor":-5,"unidad":"W"}}'
check "Rechaza datos inválidos" 400

req GET "/solicitudes/$SOL";        check "Ver solicitud" 200
req GET /solicitudes/SOL-999;       check "Solicitud inexistente" 404

echo "── Hito 3: proyecto + cuotas"
req POST /proyectos "{\"solicitudId\":\"$SOL\",\"valorTotalCop\":10000000,\"subsidioPct\":60,\"numeroCuotas\":3}"
check "Crear proyecto" 201
PRY=$(campo 'o.id')
echo "   $PRY -> financiado \$$(campo 'o.financiadoCop'), cuotas: $(campo 'o.cuotas.map(c => c.id + " $" + c.montoCop).join(", ")')"

req POST /proyectos "{\"solicitudId\":\"$SOL\",\"valorTotalCop\":10000000,\"numeroCuotas\":3}"
check "No duplica proyecto" 409

req GET "/proyectos/$PRY";          check "Ver proyecto" 200
echo "   Resumen: $(campo 'JSON.stringify(o.resumen)')"

echo "──"
if [[ $FALLOS -eq 0 ]]; then echo "🎉 Todo OK"; else echo "⚠️  $FALLOS prueba(s) fallaron"; exit 1; fi
