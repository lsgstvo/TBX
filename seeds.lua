-- seeds.lua
-- Popula o banco com notícias reais de games — março de 2026
-- Execute uma única vez: lua seeds.lua

local db = require("db")

print("🌱 Iniciando seed do banco de dados...")

local conn = db.connect()
conn:exec("DELETE FROM noticias")
conn:exec("DELETE FROM jogos")
conn:exec("DELETE FROM sqlite_sequence WHERE name='noticias' OR name='jogos'")
print("  ✓ Tabelas limpas")

-- ─── Jogos / Ranking ─────────────────────────────────────────────────────────
local jogos = {
  { nome = "Valorant",            genero = "FPS Tático",    players = "22 milhões/dia",   posicao = 1 },
  { nome = "League of Legends",   genero = "MOBA",          players = "150 milhões reg.", posicao = 2 },
  { nome = "Counter-Strike 2",    genero = "FPS Tático",    players = "1.3 milhões/pico", posicao = 3 },
  { nome = "Minecraft",           genero = "Sandbox",       players = "170 milhões reg.", posicao = 4 },
  { nome = "Fortnite",            genero = "Battle Royale", players = "100 milhões reg.", posicao = 5 },
}

for _, j in ipairs(jogos) do
  db.criar_jogo(j.nome, j.genero, j.players, j.posicao)
  print(string.format("  ✓ Jogo: %s", j.nome))
end

-- ─── Notícias reais — Março 2026 ─────────────────────────────────────────────
local noticias = {
  {
    titulo   = "GTA 6 confirmado para 2026 e já é o lançamento mais aguardado da história",
    conteudo = "A Rockstar Games confirmou Grand Theft Auto VI para 2026, e o título já é apontado como um dos maiores lançamentos da história do entretenimento. O jogo se passa em Vice City e promete um mundo aberto sem precedentes, com gráficos e mecânicas de nova geração. A Rockstar também garantiu oficialmente a marca GTA VI no Brasil, acalmando fãs que temiam um novo adiamento.",
    jogo     = "GTA 6",
  },
  {
    titulo   = "Death Stranding 2 chega ao PC em 19 de março após exclusividade no PS5",
    conteudo = "O aguardado Death Stranding 2: On the Beach, de Hideo Kojima, encerra seu período de exclusividade no PlayStation 5 e chega ao PC no dia 19 de março de 2026. O jogo foi aclamado pela crítica por sua narrativa densa e mecânicas inovadoras de entrega e construção de rotas. Jogadores de PC poderão aproveitar gráficos aprimorados e suporte a taxas de quadros mais altas.",
    jogo     = "Death Stranding 2",
  },
  {
    titulo   = "Crimson Desert lança em 19 de março no PS5, Xbox Series e PC",
    conteudo = "A Pearl Abyss finalmente lança Crimson Desert, seu ambicioso RPG de ação em mundo aberto, no dia 19 de março para PlayStation 5, Xbox Series e PC. O jogo acompanha um grupo de mercenários no vasto continente de Pywel e promete combate fluido, mundo aberto repleto de detalhes e uma narrativa épica. O título é visto como uma das maiores apostas da publisher sul-coreana.",
    jogo     = "Crimson Desert",
  },
  {
    titulo   = "Pokémon Pokopia é lançado com exclusividade no Nintendo Switch 2",
    conteudo = "Pokémon Pokopia chegou ao Nintendo Switch 2 no dia 5 de março. No jogo, os jogadores controlam um Ditto e constroem seu próprio paraíso, copiando habilidades de outros Pokémon para transformar um mundo desolado em uma utopia. O título é um dos destaques do mês de março para donos do novo hardware da Nintendo.",
    jogo     = "Pokémon Pokopia",
  },
  {
    titulo   = "Marathon, o shooter de extração da Bungie, lança em 5 de março",
    conteudo = "A Bungie lançou Marathon no dia 5 de março, seu aguardado shooter de extração. O jogo marca o retorno de uma franquia clássica da empresa com mecânicas modernas de looter-shooter em primeira pessoa. O título chega em um momento importante para a Bungie, que busca reconquistar a confiança dos jogadores após as dificuldades recentes.",
    jogo     = "Marathon",
  },
  {
    titulo   = "Legacy of Kain: Defiance Remastered chega para todas as plataformas",
    conteudo = "O clássico Legacy of Kain: Defiance ganhou uma versão remasterizada lançada no dia 2 de março para PS4, PS5, PC, Xbox One, Xbox Series, Switch e Switch 2. O remaster traz gráficos modernizados, melhorias de performance e todo o conteúdo original do jogo de 2003, que acompanhava Raziel e Kain em Nosgoth.",
    jogo     = "Legacy of Kain",
  },
  {
    titulo   = "Nintendo Switch 2 domina lançamentos de março com extensa lineup",
    conteudo = "Março de 2026 é considerado um mês historicamente agitado para os donos do Nintendo Switch 2. Além de Pokémon Pokopia, o console recebeu Scott Pilgrim EX, Super Mario Bros. Wonder Edition e diversas outras ports e títulos inéditos. A Nintendo continua apostando em um calendário denso para consolidar sua nova plataforma no mercado.",
    jogo     = "Nintendo Switch 2",
  },
  {
    titulo   = "PS Plus Extra e Premium de março terão Tekken Dark Resurrection confirmado",
    conteudo = "A Sony confirmou que Tekken Dark Resurrection será um dos títulos disponíveis para assinantes do PS Plus Premium em março de 2026. O clássico originalmente lançado para PSP em 2005 é considerado um dos melhores jogos da franquia Tekken. O anúncio completo da lista de março está previsto para o dia 11, por volta das 19h30 no horário de Brasília.",
    jogo     = "Tekken",
  },
  {
    titulo   = "007 First Light apresenta James Bond mais jovem em novo jogo da IO Interactive",
    conteudo = "007 First Light, desenvolvido pela IO Interactive — criadora da série Hitman — é um dos destaques de março no PC e consoles. O jogo apresenta uma versão mais jovem de James Bond em uma história de origem, prometendo mecânicas de espionagem, infiltração e ação. É a primeira vez em anos que a franquia Bond recebe um título de alto orçamento.",
    jogo     = "007 First Light",
  },
  {
    titulo   = "Halo: Campaign Evolved e Forza Horizon 6 abrem 2026 com força para a Microsoft",
    conteudo = "A Microsoft aposta em 2026 com lançamentos fortes para o Xbox, incluindo Halo: Campaign Evolved e Forza Horizon 6. Os títulos fazem parte de uma estratégia para reconquistar espaço no mercado de consoles e fortalecer o Xbox Game Pass. A empresa também promete expansão do uso de inteligência artificial nos jogos via Gaming Copilot.",
    jogo     = "Xbox",
  },
}

for _, n in ipairs(noticias) do
  db.criar_noticia(n.titulo, n.conteudo, n.jogo)
  print(string.format("  ✓ Notícia: %s", n.titulo:sub(1, 55) .. "..."))
end

print(string.format("\n✅ Seed concluído! %d jogos | %d notícias inseridos.", #jogos, #noticias))
db.close()