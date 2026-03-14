#!/usr/bin/env bash
# Baixa imagens de capa para os jogos cadastrados no Portal Gamer
# Salva em static/uploads/ e atualiza imagem_url no banco via Lua

mkdir -p static/uploads

echo "📥 Baixando imagens dos jogos..."

download_and_register() {
  local nome="$1"
  local url="$2"
  local arquivo="$3"
  local destino="static/uploads/$arquivo"

  if [ -f "$destino" ]; then
    echo "  ✅ $nome já existe ($arquivo), pulando."
  else
    echo "  ⬇️  Baixando $nome..."
    if curl -fsSL -A "Mozilla/5.0" -o "$destino" "$url" && [ -s "$destino" ]; then
      echo "  ✅ $nome salvo como $arquivo"
    else
      rm -f "$destino"
      echo "  ❌ Falha ao baixar $nome"
      return
    fi
  fi

  # Atualiza imagem_url no banco via Lua
  lua -e "
    local db = require('lsqlite3').open('portal_gamer.db')
    db:exec(string.format(
      [[UPDATE jogos SET imagem_url = '%s' WHERE nome = '%s']],
      '/static/uploads/$arquivo', '$nome'
    ))
    db:close()
    print('  💾 Banco: $nome')
  "
}

# ── Steam CDN (imagens oficiais, públicas) ────────────────────────────────────

# Valorant (Riot CDN)
download_and_register \
  "Valorant" \
  "https://i.pinimg.com/736x/c3/f5/66/c3f56646de190d156825cbb204a82ac2.jpg" \
  "Valorant.jpg"

# League of Legends
download_and_register \
  "League of Legends" \
  "https://cdn2.steamgriddb.com/icon/4c6d1c7c8ab9b70975050d15b54b5778/32/256x256.png" \
  "league_of_legends.png"

# Counter-Strike 2
download_and_register \
  "Counter-Strike 2" \
  "https://cdn.cloudflare.steamstatic.com/steam/apps/730/header.jpg" \
  "counter_strike2.jpg"

# Minecraft
download_and_register \
  "Minecraft" \
  "https://cdn.cloudflare.steamstatic.com/steam/apps/1672970/header.jpg" \
  "minecraft.jpg"

# Fortnite  (Epic não tem steam, usa CDN alternativo)
download_and_register \
  "Fortnite" \
  "https://cdn2.steamgriddb.com/icon/daa3e77dc2ee62fa1b01b3c5d60d6a0f/32/256x256.png" \
  "fortnite.png"

echo ""
echo "✅ Concluído! Arquivos em static/uploads/"
ls -lh static/uploads/
