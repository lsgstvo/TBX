local lapis  = require("lapis")
local db     = require("db")
local auth   = require("auth")

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

app:get("/noticias", function(self)
  self.noticias = db.get_noticias()
  return { render = "noticias" }
end)

app:get("/noticias/:id", function(self)
  local noticia = db.get_noticia(self.params.id)
  if not noticia then
    return { status = 404, render = "erro" }
  end
  self.noticia = noticia
  return { render = "noticia_detalhe" }
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

-- ─── Admin: Login ─────────────────────────────────────────────────────────────

app:get("/admin/login", function(self)
  if auth.logged_in(self) then
    return { redirect_to = "/admin" }
  end
  self.erro = self.session.login_erro
  self.session.login_erro = nil
  return { render = "admin.login", layout = "admin.layout" }
end)

app:post("/admin/login", function(self)
  local usuario = self.params.usuario or ""
  local senha   = self.params.senha   or ""

  if auth.check_credentials(usuario, senha) then
    self.session.admin = true
    return { redirect_to = "/admin" }
  end

  self.session.login_erro = "Usuário ou senha incorretos."
  return { redirect_to = "/admin/login" }
end)

-- ─── Admin: Logout ────────────────────────────────────────────────────────────

app:get("/admin/logout", function(self)
  self.session.admin = nil
  return { redirect_to = "/admin/login" }
end)

-- ─── Admin: Painel principal ──────────────────────────────────────────────────

app:get("/admin", function(self)
  if not auth.require_login(self) then return end
  self.noticias = db.get_noticias()
  self.jogos    = db.get_jogos()
  return { render = "admin.painel", layout = "admin.layout" }
end)

-- ─── Admin: Nova notícia (formulário) ────────────────────────────────────────

app:get("/admin/noticias/nova", function(self)
  if not auth.require_login(self) then return end
  self.jogos = db.get_jogos()
  self.erro  = self.session.form_erro
  self.session.form_erro = nil
  return { render = "admin.noticia_form", layout = "admin.layout" }
end)

-- ─── Admin: Nova notícia (salvar) ────────────────────────────────────────────

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

-- ─── Admin: Deletar notícia ───────────────────────────────────────────────────

app:post("/admin/noticias/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_noticia(self.params.id)
  return { redirect_to = "/admin" }
end)

return app