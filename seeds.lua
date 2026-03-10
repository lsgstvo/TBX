-- Popula o banco de dados com dados iniciais para desenvolvimento.
-- Execute uma única vez: lua seeds.lua

local db = require("db")

print("🌱 Iniciando seed do banco de dados...")

-- ─── Limpa dados antigos (útil ao re-rodar o seed) ──────────────────────────
local conn = db.connect()
conn:exec("DELETE FROM noticias")
conn:exec("DELETE FROM jogos")
conn:exec("DELETE FROM sqlite_sequence WHERE name='noticias' OR name='jogos'")
print("  ✓ Tabelas limpas")

-- ─── Jogos / Ranking ─────────────────────────────────────────────────────────
local jogos = {
  { nome = "Valorant",              genero = "FPS Tático",    players = "22 milhões/dia",  posicao = 1 },
  { nome = "League of Legends",     genero = "MOBA",          players = "150 milhões reg.", posicao = 2 },
  { nome = "Counter-Strike 2",      genero = "FPS Tático",    players = "1.3 milhões/pico", posicao = 3 },
  { nome = "Minecraft",             genero = "Sandbox",       players = "170 milhões reg.", posicao = 4 },
  { nome = "Fortnite",              genero = "Battle Royale", players = "100 milhões reg.", posicao = 5 },
}

for _, j in ipairs(jogos) do
  db.criar_jogo(j.nome, j.genero, j.players, j.posicao)
  print(string.format("  ✓ Jogo inserido: %s (#%d)", j.nome, j.posicao))
end

-- ─── Notícias ────────────────────────────────────────────────────────────────
local noticias = {
  {
    titulo   = "Novo update de Valorant adiciona agente e mapa inéditos",
    conteudo = "A Riot Games lançou o Episódio 9, trazendo um novo agente do tipo Controlador e um mapa ambientado no Japão feudal. O patch também rebalanceou diversas armas.",
    jogo     = "Valorant",
  },
  {
    titulo   = "League of Legends anuncia novo campeão: Ambessa",
    conteudo = "Inspirada na série Arcane, Ambessa chega como lutadora de linha superior com mecânicas únicas de mobilidade e dano em área. Disponível no patch 14.20.",
    jogo     = "League of Legends",
  },
  {
    titulo   = "CS2 bate recorde histórico de jogadores simultâneos",
    conteudo = "Counter-Strike 2 registrou mais de 1,8 milhão de jogadores simultâneos na última semana, superando o pico anterior do CS:GO e consolidando-se como o FPS mais jogado no Steam.",
    jogo     = "Counter-Strike 2",
  },
  {
    titulo   = "Minecraft lança update 'Tricky Trials' com novo bioma",
    conteudo = "A atualização 1.21 traz as Trial Chambers, novo bioma subterrâneo repleto de armadilhas e mobs inéditos. O Breeze é o novo mob hostil e o Mace é a nova arma exclusiva do update.",
    jogo     = "Minecraft",
  },
  {
    titulo   = "Fortnite anuncia crossover com Star Wars para a Temporada 3",
    conteudo = "A Epic Games confirmou que a próxima temporada trará skins e itens de Star Wars, incluindo sabres de luz como armas utilizáveis e uma área temática inspirada em Tatooine no mapa.",
    jogo     = "Fortnite",
  },
}

for _, n in ipairs(noticias) do
  db.criar_noticia(n.titulo, n.conteudo, n.jogo)
  print(string.format("  ✓ Notícia inserida: %s", n.titulo:sub(1, 50) .. "..."))
end

print("\n✅ Seed concluído com sucesso!")
print(string.format("   %d jogos | %d notícias inseridos", #jogos, #noticias))
db.close()