-- Aplicação principal do Portal Gamer
-- Todas as rotas agora leem dados reais do banco SQLite via db.lua

local lapis = require("lapis")
local db    = require("db")

local app = lapis.Application()
app.layout = require("views.layout")

-- ─── Página Principal ────────────────────────────────────────────────────────
app:get("/", function(self)
  -- Busca as 5 notícias mais recentes para exibir na home
  self.noticias = db.get_noticias()
  -- Limita a 5 itens na home
  local recentes = {}
  for i = 1, math.min(5, #self.noticias) do
    table.insert(recentes, self.noticias[i])
  end
  self.noticias = recentes
  return { render = "index" }
end)

-- ─── Página de Ranking ───────────────────────────────────────────────────────
app:get("/ranking", function(self)
  self.jogos = db.get_jogos()
  return { render = "ranking" }
end)

-- ─── Página de Notícias (listagem completa) ──────────────────────────────────
app:get("/noticias", function(self)
  self.noticias = db.get_noticias()
  return { render = "noticias" }
end)

-- ─── Detalhe de uma Notícia ──────────────────────────────────────────────────
app:get("/noticias/:id", function(self)
  local noticia = db.get_noticia(self.params.id)
  if not noticia then
    return { status = 404, render = "erro" }
  end
  self.noticia = noticia
  return { render = "noticia_detalhe" }
end)

-- ─── API JSON: Notícias ──────────────────────────────────────────────────────
-- Endpoint simples para consumo externo ou AJAX futuro
app:get("/api/noticias", function(self)
  local noticias = db.get_noticias()
  return {
    json = { status = "ok", data = noticias, total = #noticias }
  }
end)

-- ─── API JSON: Ranking ───────────────────────────────────────────────────────
app:get("/api/ranking", function(self)
  local jogos = db.get_jogos()
  return {
    json = { status = "ok", data = jogos, total = #jogos }
  }
end)

return app