-- app.lua
local lapis = require("lapis")
local db    = require("db")
local auth  = require("auth")

local app = lapis.Application()
app.layout = require("views.layout")

-- ─── Rotas Públicas ──────────────────────────────────────────────────────────

app:get("/", function(self)
  local todas = db.get_noticias()
  local recentes = {}
  for i = 1, math.min(5, #todas) do
    table.insert(recentes, todas[i])
  end
  self.noticias = recentes
  return { render = "index" }
end)

app:get("/ranking", function(self)
  self.jogos = db.get_jogos()
  return { render = "ranking" }
end)

-- ─── Notícias com paginação e busca ──────────────────────────────────────────

app:get("/noticias", function(self)
  local termo  = self.params.q or ""
  local pagina = tonumber(self.params.p) or 1

  if termo ~= "" then
    -- Modo busca: retorna todos os resultados sem paginação
    self.noticias   = db.buscar_noticias(termo)
    self.termo      = termo
    self.paginacao  = nil
  else
    -- Modo normal: paginado
    local resultado = db.get_noticias_paginadas(pagina, 6)
    self.noticias   = resultado.rows
    self.paginacao  = resultado
    self.termo      = ""
  end

  return { render = "noticias" }
end)

app:get("/noticias/:id", function(self)
  local noticia = db.get_noticia(self.params.id)
  if not noticia then
    return { status = 404, render = "erro" }
  end
  self.noticia = noticia
  -- Notícias relacionadas do mesmo jogo (exceto a atual)
  if noticia.jogo and noticia.jogo ~= "" then
    local relacionadas = db.get_noticias_por_jogo(noticia.jogo)
    local filtradas = {}
    for _, n in ipairs(relacionadas) do
      if n.id ~= noticia.id then
        table.insert(filtradas, n)
        if #filtradas >= 3 then break end
      end
    end
    self.relacionadas = filtradas
  end
  return { render = "noticia_detalhe" }
end)

-- ─── Página de detalhes do jogo ───────────────────────────────────────────────

app:get("/jogos/:nome", function(self)
  local nome = self.params.nome
  -- Decodifica espaços (%20 → " ")
  nome = nome:gsub("%%20", " "):gsub("+", " ")

  local jogo = db.get_jogo_por_nome(nome)
  if not jogo then
    return { status = 404, render = "erro" }
  end

  self.jogo     = jogo
  self.noticias = db.get_noticias_por_jogo(jogo.nome)
  return { render = "jogo_detalhe" }
end)

-- ─── API JSON ─────────────────────────────────────────────────────────────────

app:get("/api/noticias", function(self)
  local noticias = db.get_noticias()
  return { json = { status = "ok", data = noticias, total = #noticias } }
end)

app:get("/api/ranking", function(self)
  local jogos = db.get_jogos()
  return { json = { status = "ok", data = jogos, total = #jogos } }
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

-- ─── Admin: Painel ────────────────────────────────────────────────────────────

app:get("/admin", function(self)
  if not auth.require_login(self) then return end
  self.noticias = db.get_noticias()
  self.jogos    = db.get_jogos()
  return { render = "admin.admin_painel", layout = "admin.admin_layout" }
end)

-- ─── Admin: Nova notícia ──────────────────────────────────────────────────────

app:get("/admin/noticias/nova", function(self)
  if not auth.require_login(self) then return end
  self.jogos = db.get_jogos()
  self.erro  = self.session.form_erro
  self.session.form_erro = nil
  return { render = "admin.admin_noticia_form", layout = "admin.admin_layout" }
end)

app:post("/admin/noticias/nova", function(self)
  if not auth.require_login(self) then return end
  local titulo   = (self.params.titulo   or ""):match("^%s*(.-)%s*$")
  local conteudo = (self.params.conteudo or ""):match("^%s*(.-)%s*$")
  local jogo     = (self.params.jogo     or ""):match("^%s*(.-)%s*$")
  if titulo == "" or conteudo == "" then
    self.session.form_erro = "Título e conteúdo são obrigatórios."
    return { redirect_to = "/admin/noticias/nova" }
  end
  db.criar_noticia(titulo, conteudo, jogo)
  return { redirect_to = "/admin" }
end)

-- ─── Admin: Editar notícia ────────────────────────────────────────────────────

app:get("/admin/noticias/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local noticia = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  self.noticia = noticia
  self.jogos   = db.get_jogos()
  self.erro    = self.session.form_erro
  self.session.form_erro = nil
  return { render = "admin.admin_noticia_editar", layout = "admin.admin_layout" }
end)

app:post("/admin/noticias/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local titulo   = (self.params.titulo   or ""):match("^%s*(.-)%s*$")
  local conteudo = (self.params.conteudo or ""):match("^%s*(.-)%s*$")
  local jogo     = (self.params.jogo     or ""):match("^%s*(.-)%s*$")
  if titulo == "" or conteudo == "" then
    self.session.form_erro = "Título e conteúdo são obrigatórios."
    return { redirect_to = "/admin/noticias/" .. self.params.id .. "/editar" }
  end
  db.editar_noticia(self.params.id, titulo, conteudo, jogo)
  return { redirect_to = "/admin" }
end)

-- ─── Admin: Deletar notícia ───────────────────────────────────────────────────

app:post("/admin/noticias/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_noticia(self.params.id)
  return { redirect_to = "/admin" }
end)

return app