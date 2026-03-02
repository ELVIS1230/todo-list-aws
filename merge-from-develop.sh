#!/bin/bash
# Script para mergear develop a master protegiendo el Jenkinsfile

set -e

echo "🔀 Mergeando develop a master..."
echo ""

# Verificar que estamos en master
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "master" ]; then
    echo "❌ Error: Debes estar en la rama master"
    echo "Ejecuta: git checkout master"
    exit 1
fi

# Guardar una copia del Jenkinsfile actual
cp Jenkinsfile /tmp/Jenkinsfile.master.backup
echo "✅ Jenkinsfile de master guardado"

# Hacer el merge sin commit
echo "🔄 Ejecutando merge..."
if git merge develop --no-commit --no-ff 2>/dev/null; then
    echo "✅ Merge completado automáticamente"
else
    echo "⚠️  Hay conflictos que resolver"
    # Si hay conflictos, mostrarlos
    git status
    echo ""
    echo "Resuelve los conflictos manualmente, excepto el Jenkinsfile"
    echo "El Jenkinsfile se restaurará automáticamente"
    echo ""
    echo "Cuando termines, presiona Enter para continuar..."
    read -r
fi

# Restaurar el Jenkinsfile de master
echo "🔒 Protegiendo Jenkinsfile de master..."
git checkout HEAD -- Jenkinsfile

# Verificar que se restauró correctamente
if diff -q Jenkinsfile /tmp/Jenkinsfile.master.backup > /dev/null; then
    echo "✅ Jenkinsfile de master restaurado correctamente"
else
    echo "⚠️  Advertencia: El Jenkinsfile puede no haberse restaurado correctamente"
fi

# Hacer el commit
echo ""
echo "📝 Haciendo commit del merge..."
git commit -m "Merge develop manteniendo Jenkinsfile de master"

echo ""
echo "✅ ¡Merge completado exitosamente!"
echo "📋 El Jenkinsfile de master se mantuvo sin cambios"
echo ""
echo "Recuerda hacer: git push origin master"
