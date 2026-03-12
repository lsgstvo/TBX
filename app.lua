-- app.lua
local lapis = require("lapis")
local db    = require("db")
local auth  = require("auth")

local app = lapis.Application()
app.layout = require("views.layout")

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function trim(s)
  return (s or ""):match("^%s*(.-)%s*$")
end

-- ─── Home ─────────────────────────────────────────────────────────────────────

app:get("/", function(self)
  self.destaques = db.get_destaques()
  local todas    = db.get_noticias()
  -- Remove destaques da lista recente para não duplicar
  local recentes = {}
  local ids_dest = {}
  for _, d in ipairs(self.destaques) do ids_dest[d.id] = true end
  for _, n in ipairs(todas) do
    if not ids_dest[n.id] then
      table.insert(recentes, n)
      if #recentes >= 5 then break end
    end
  end
  self.noticias = recentes
  return { render = "index" }
end)

-- ─── Ranking ─────────────────────────────────────────────────────────────────

app:get("/ranking", function(self)
  self.jogos = db.get_jogos()
  return { render = "ranking" }
end)

-- ─── Detalhe de Jogo ─────────────────────────────────────────────────────────

app:get("/jogos/:nome", function(self)
  local nome = self.params.nome:gsub("%%20", " "):gsub("+", " ")
  local jogo = db.get_jogo_por_nome(nome)
  if not jogo then return { status = 404, render = "erro" } end
  self.jogo     = jogo
  self.noticias = db.get_noticias_do_jogo(nome)
  return { render = "jogo_detalhe" }
end)

-- ─── Notícias (paginação + busca + filtro categoria) ──────────────────────────

app:get("/noticias", function(self)
  local termo     = trim(self.params.q)
  local categoria = trim(self.params.categoria)

  if termo ~= "" then
    self.noticias   = db.buscar_noticias(termo)
    self.termo      = termo
    self.modo_busca = true
  else
    local pagina    = tonumber(self.params.pagina) or 1
    local resultado = db.get_noticias_paginado(pagina, 6, categoria ~= "" and categoria or nil)
    self.noticias      = resultado.rows
    self.pagina        = resultado.pagina
    self.total_paginas = resultado.total_paginas
    self.total         = resultado.total
    self.categoria_ativa = categoria
    self.modo_busca    = false
  end

  self.categorias = db.get_categorias()
  return { render = "noticias" }
end)

-- ─── Detalhe de Notícia ───────────────────────────────────────────────────────

app:get("/noticias/:id", function(self)
  local noticia = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  self.noticia = noticia
  return { render = "noticia_detalhe" }
end)

-- ─── Categoria ───────────────────────────────────────────────────────────────

app:get("/categoria/:nome", function(self)
  local nome      = self.params.nome
  self.noticias   = db.get_noticias_por_categoria(nome)
  self.categoria  = nome
  self.categorias = db.get_categorias()
  return { render = "noticias" }
end)

-- ─── API JSON ─────────────────────────────────────────────────────────────────

app:get("/api/noticias", function(self)
  return { json = { status = "ok", data = db.get_noticias() } }
end)

app:get("/api/ranking", function(self)
  return { json = { status = "ok", data = db.get_jogos() } }
end)

-- ─── Admin: Login / Logout ────────────────────────────────────────────────────

app:get("/admin/login", function(self)
  if auth.logged_in(self) then return { redirect_to = "/admin" } end
  self.erro = self.session.login_erro
  self.session.login_erro = nil
  return { render = "admin.admin_login", layout = "admin.admin_layout" }
end)

app:post("/admin/login", function(self)
  if auth.check_credentials(self.params.usuario or "", self.params.senha or "") then
    self.session.admin = true
    return { redirect_to = "/admin" }
  end
  self.session.login_erro = "Usuário ou senha incorretos."
  return { redirect_to = "/admin/login" }
end)

app:get("/admin/logout", function(self)
  self.session.admin = nil
  return { redirect_to = "/admin/login" }
end)

-- ─── Admin: Painel ───────────────────────────────────────────────────────────

app:get("/admin", function(self)
  if not auth.require_login(self) then return end
  self.noticias = db.get_noticias()
  self.jogos    = db.get_jogos()
  return { render = "admin.admin_painel", layout = "admin.admin_layout" }
end)

-- ─── Admin: Notícias ─────────────────────────────────────────────────────────

app:get("/admin/noticias/nova", function(self)
  if not auth.require_login(self) then return end
  self.jogos      = db.get_jogos()
  self.categorias = db.get_categorias()
  self.erro       = self.session.form_erro
  self.session.form_erro = nil
  return { render = "admin.admin_noticia_form", layout = "admin.admin_layout" }
end)

app:post("/admin/noticias/nova", function(self)
  if not auth.require_login(self) then return end
  local titulo    = trim(self.params.titulo)
  local conteudo  = trim(self.params.conteudo)
  local jogo      = trim(self.params.jogo)
  local categoria = trim(self.params.categoria)
  local destaque  = self.params.destaque == "1"
  if titulo == "" or conteudo == "" then
    self.session.form_erro = "Título e conteúdo são obrigatórios."
    return { redirect_to = "/admin/noticias/nova" }
  end
  db.criar_noticia(titulo, conteudo, jogo, categoria, destaque)
  return { redirect_to = "/admin" }
end)

app:get("/admin/noticias/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local noticia = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  self.noticia    = noticia
  self.jogos      = db.get_jogos()
  self.categorias = db.get_categorias()
  self.erro       = self.session.form_erro
  self.session.form_erro = nil
  return { render = "admin.admin_noticia_editar", layout = "admin.admin_layout" }
end)

app:post("/admin/noticias/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local titulo    = trim(self.params.titulo)
  local conteudo  = trim(self.params.conteudo)
  local jogo      = trim(self.params.jogo)
  local categoria = trim(self.params.categoria)
  local destaque  = self.params.destaque == "1"
  if titulo == "" or conteudo == "" then
    self.session.form_erro = "Título e conteúdo são obrigatórios."
    return { redirect_to = "/admin/noticias/" .. self.params.id .. "/editar" }
  end
  db.editar_noticia(self.params.id, titulo, conteudo, jogo, categoria, destaque)
  return { redirect_to = "/admin" }
end)

app:post("/admin/noticias/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_noticia(self.params.id)
  return { redirect_to = "/admin" }
end)

-- ─── Admin: Jogos ─────────────────────────────────────────────────────────────

app:get("/admin/jogos/novo", function(self)
  if not auth.require_login(self) then return end
  self.erro = self.session.form_erro
  self.session.form_erro = nil
  return { render = "admin.admin_jogo_form", layout = "admin.admin_layout" }
end)

app:post("/admin/jogos/novo", function(self)
  if not auth.require_login(self) then return end
  local nome       = trim(self.params.nome)
  local genero     = trim(self.params.genero)
  local players    = trim(self.params.players)
  local posicao    = tonumber(self.params.posicao) or 0
  local descricao  = trim(self.params.descricao)
  local imagem_url = trim(self.params.imagem_url)
  if nome == "" or players == "" then
    self.session.form_erro = "Nome e base de jogadores são obrigatórios."
    return { redirect_to = "/admin/jogos/novo" }
  end
  db.criar_jogo(nome, genero, players, posicao, descricao, imagem_url)
  return { redirect_to = "/admin" }
end)

app:get("/admin/jogos/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local jogo = db.get_jogo(self.params.id)
  if not jogo then return { status = 404, render = "erro" } end
  self.jogo = jogo
  self.erro = self.session.form_erro
  self.session.form_erro = nil
  return { render = "admin.admin_jogo_editar", layout = "admin.admin_layout" }
end)

app:post("/admin/jogos/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local nome       = trim(self.params.nome)
  local genero     = trim(self.params.genero)
  local players    = trim(self.params.players)
  local posicao    = tonumber(self.params.posicao) or 0
  local descricao  = trim(self.params.descricao)
  local imagem_url = trim(self.params.imagem_url)
  if nome == "" or players == "" then
    self.session.form_erro = "Nome e base de jogadores são obrigatórios."
    return { redirect_to = "/admin/jogos/" .. self.params.id .. "/editar" }
  end
  db.editar_jogo(self.params.id, nome, genero, players, posicao, descricao, imagem_url)
  return { redirect_to = "/admin" }
end)

app:post("/admin/jogos/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_jogo(self.params.id)
  return { redirect_to = "/admin" }
end)

return app