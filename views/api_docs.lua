-- views/api_docs.lua
local Widget = require("lapis.html").Widget

-- Helper: renderiza um bloco de endpoint
local function endpoint(metodo, rota, descricao, exemplo_resp)
  return div({ class = "doc-endpoint" }, function()
    div({ class = "doc-header" }, function()
      span({ class = "doc-metodo doc-" .. metodo:lower() }, metodo)
      code({ class = "doc-rota" }, rota)
    end)
    p({ class = "doc-desc" }, descricao)
    if exemplo_resp then
      div({ class = "doc-exemplo" }, function()
        pre({ class = "doc-code" }, exemplo_resp)
      end)
    end
  end)
end

return Widget:extend(function(self)
  div({ class = "shadow-card doc-hero" }, function()
    h2("📖 API Pública — Portal Gamer")
    p("API REST simples, somente leitura, sem autenticação. Todas as respostas são em JSON (UTF-8).")
    div({ class = "doc-base" }, function()
      span("Base URL: ")
      code("http://localhost:8080")
    end)
  end)

  -- Seção: Notícias
  div({ class = "shadow-card mt-2 doc-secao" }, function()
    h3("📰 Notícias")

    endpoint("GET", "/api/noticias",
      "Retorna todas as notícias, ordenadas por destaque e data (mais recente primeiro).",
      [[{
  "status": "ok",
  "data": [
    {
      "id": 1,
      "titulo": "GTA 6 confirmado para 2026",
      "conteudo": "...",
      "jogo": "GTA 6",
      "categoria": "Lançamento",
      "destaque": 1,
      "views": 142,
      "criado_em": "2026-03-11 00:39:20"
    }
  ]
}]])

    endpoint("GET", "/api/busca?q={termo}",
      "Busca notícias por título, jogo ou categoria. Retorna até 8 resultados. Parâmetro q obrigatório (mínimo 2 caracteres).",
      [[{
  "status": "ok",
  "data": [
    {
      "id": 3,
      "titulo": "Crimson Desert lança em março",
      "categoria": "Lançamento",
      "jogo": "Crimson Desert"
    }
  ],
  "total": 1
}]])
  end)

  -- Seção: Jogos
  div({ class = "shadow-card mt-2 doc-secao" }, function()
    h3("🎮 Jogos")

    endpoint("GET", "/api/ranking",
      "Retorna todos os jogos do ranking, ordenados por posição (crescente).",
      [[{
  "status": "ok",
  "data": [
    {
      "id": 1,
      "nome": "Valorant",
      "genero": "FPS Tático",
      "players": "22 milhões/dia",
      "posicao": 1,
      "descricao": "...",
      "imagem_url": "/static/uploads/valorant.jpg"
    }
  ]
}]])
  end)

  -- Seção: Feeds
  div({ class = "shadow-card mt-2 doc-secao" }, function()
    h3("📡 Feeds")

    endpoint("GET", "/rss",
      "Feed RSS 2.0 com as últimas 20 notícias. Content-Type: application/rss+xml; charset=UTF-8.",
      nil)

    endpoint("GET", "/sitemap.xml",
      "Sitemap XML com todas as páginas públicas. Content-Type: application/xml; charset=UTF-8.",
      nil)
  end)

  -- Seção: Detalhes
  div({ class = "shadow-card mt-2 doc-secao" }, function()
    h3("ℹ️ Notas")
    ul({ class = "doc-notas" }, function()
      li("Todas as rotas são somente leitura (GET). Escrita requer autenticação de admin.")
      li("Não há rate limiting configurado por padrão em ambiente local.")
      li("Campos de texto podem conter HTML especial escapado.")
      li("Datas no formato SQLite: YYYY-MM-DD HH:MM:SS (UTC).")
      li("O campo views é incrementado a cada acesso à página da notícia.")
    end)
  end)
end)