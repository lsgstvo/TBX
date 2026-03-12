-- app.lua
local lapis = require("lapis")
local db    = require("db")
local auth  = require("auth")

local app = lapis.Application()
app.layout = require("views.layout")

local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end

-- ─── Home ─────────────────────────────────────────────────────────────────────

app:get("/", function(self)
  self.destaques = db.get_destaques()
  local todas    = db.get_noticias()
  local ids_dest = {}
  for _, d in ipairs(self.destaques) do ids_dest[d.id] = true end
  local recentes = {}
  for _, n in ipairs(todas) do
    if not ids_dest[n.id] then
      table.insert(recentes, n)
      if #recentes >= 5 then break end
    end
  end
  self.noticias    = recentes
  self.mais_vistas = db.get_mais_vistas(5)
  return { render = "index" }
end)

-- ─── Sobre ────────────────────────────────────────────────────────────────────

app:get("/sobre", function(self)
  return { render = "sobre" }
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

-- ─── Notícias ────────────────────────────────────────────────────────────────

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
    self.noticias        = resultado.rows
    self.pagina          = resultado.pagina
    self.total_paginas   = resultado.total_paginas
    self.total           = resultado.total
    self.categoria_ativa = categoria
    self.modo_busca      = false
  end
  self.categorias = db.get_categorias()
  return { render = "noticias" }
end)

-- ─── Detalhe de Notícia (com views e comentários) ─────────────────────────────

app:get("/noticias/:id", function(self)
  local noticia = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  -- Incrementa visualizações
  db.incrementar_views(self.params.id)
  self.noticia     = noticia
  self.comentarios = db.get_comentarios(self.params.id)
  self.erro_coment = self.session.coment_erro
  self.session.coment_erro = nil
  return { render = "noticia_detalhe" }
end)

-- ─── POST: Enviar comentário ──────────────────────────────────────────────────

app:post("/noticias/:id/comentar", function(self)
  local autor    = trim(self.params.autor)
  local conteudo = trim(self.params.conteudo)

  if conteudo == "" then
    self.session.coment_erro = "O comentário não pode estar vazio."
    return { redirect_to = "/noticias/" .. self.params.id }
  end

  -- Limite básico de tamanho
  if #conteudo > 800 then
    self.session.coment_erro = "Comentário muito longo (máx. 800 caracteres)."
    return { redirect_to = "/noticias/" .. self.params.id }
  end

  db.criar_comentario(
    self.params.id,
    autor ~= "" and autor or "Anônimo",
    conteudo
  )
  return { redirect_to = "/noticias/" .. self.params.id .. "#comentarios" }
end)

-- ─── Categoria ───────────────────────────────────────────────────────────────

app:get("/categoria/:nome", function(self)
  self.noticias        = db.get_noticias_por_categoria(self.params.nome)
  self.categoria       = self.params.nome
  self.categorias      = db.get_categorias()
  self.modo_busca      = false
  self.pagina          = 1
  self.total_paginas   = 1
  return { render = "noticias" }
end)

-- ─── RSS Feed ─────────────────────────────────────────────────────────────────

app:get("/rss", function(self)
  local noticias = db.get_noticias()
  -- Limita a 20 itens no feed
  local items = {}
  for i = 1, math.min(20, #noticias) do table.insert(items, noticias[i]) end

  local xml = '<?xml version="1.0" encoding="UTF-8"?>\n'
  xml = xml .. '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">\n'
  xml = xml .. '  <channel>\n'
  xml = xml .. '    <title>Portal Gamer</title>\n'
  xml = xml .. '    <link>http://localhost:8080</link>\n'
  xml = xml .. '    <description>As últimas notícias do mundo dos games</description>\n'
  xml = xml .. '    <language>pt-BR</language>\n'
  xml = xml .. '    <atom:link href="http://localhost:8080/rss" rel="self" type="application/rss+xml"/>\n'

  for _, n in ipairs(items) do
    -- Escapa caracteres especiais XML
    local titulo   = n.titulo:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    local conteudo = n.conteudo:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    xml = xml .. '    <item>\n'
    xml = xml .. '      <title>' .. titulo .. '</title>\n'
    xml = xml .. '      <link>http://localhost:8080/noticias/' .. n.id .. '</link>\n'
    xml = xml .. '      <guid>http://localhost:8080/noticias/' .. n.id .. '</guid>\n'
    xml = xml .. '      <pubDate>' .. n.criado_em .. '</pubDate>\n'
    xml = xml .. '      <category>' .. n.categoria .. '</category>\n'
    xml = xml .. '      <description>' .. conteudo:sub(1, 300) .. '...</description>\n'
    xml = xml .. '    </item>\n'
  end

  xml = xml .. '  </channel>\n</rss>'

  return { content_type = "application/rss+xml", layout = false, xml }
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
  self.noticias    = db.get_noticias()
  self.jogos       = db.get_jogos()
  self.comentarios = db.get_todos_comentarios()
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
  local titulo = trim(self.params.titulo); local conteudo = trim(self.params.conteudo)
  if titulo == "" or conteudo == "" then
    self.session.form_erro = "Título e conteúdo são obrigatórios."
    return { redirect_to = "/admin/noticias/nova" }
  end
  db.criar_noticia(titulo, conteudo, trim(self.params.jogo),
    trim(self.params.categoria), self.params.destaque == "1")
  return { redirect_to = "/admin" }
end)

app:get("/admin/noticias/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local noticia = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  self.noticia = noticia; self.jogos = db.get_jogos(); self.categorias = db.get_categorias()
  self.erro = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_noticia_editar", layout = "admin.admin_layout" }
end)

app:post("/admin/noticias/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local titulo = trim(self.params.titulo); local conteudo = trim(self.params.conteudo)
  if titulo == "" or conteudo == "" then
    self.session.form_erro = "Título e conteúdo são obrigatórios."
    return { redirect_to = "/admin/noticias/" .. self.params.id .. "/editar" }
  end
  db.editar_noticia(self.params.id, titulo, conteudo, trim(self.params.jogo),
    trim(self.params.categoria), self.params.destaque == "1")
  return { redirect_to = "/admin" }
end)

app:post("/admin/noticias/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_noticia(self.params.id)
  return { redirect_to = "/admin" }
end)

-- ─── Admin: Comentários ───────────────────────────────────────────────────────

app:post("/admin/comentarios/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_comentario(self.params.id)
  return { redirect_to = "/admin#comentarios" }
end)

-- ─── Admin: Jogos ─────────────────────────────────────────────────────────────

app:get("/admin/jogos/novo", function(self)
  if not auth.require_login(self) then return end
  self.erro = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_jogo_form", layout = "admin.admin_layout" }
end)

app:post("/admin/jogos/novo", function(self)
  if not auth.require_login(self) then return end
  local nome = trim(self.params.nome); local players = trim(self.params.players)
  if nome == "" or players == "" then
    self.session.form_erro = "Nome e base de jogadores são obrigatórios."
    return { redirect_to = "/admin/jogos/novo" }
  end
  db.criar_jogo(nome, trim(self.params.genero), players,
    tonumber(self.params.posicao) or 0,
    trim(self.params.descricao), trim(self.params.imagem_url))
  return { redirect_to = "/admin" }
end)

app:get("/admin/jogos/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local jogo = db.get_jogo(self.params.id)
  if not jogo then return { status = 404, render = "erro" } end
  self.jogo = jogo; self.erro = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_jogo_editar", layout = "admin.admin_layout" }
end)

app:post("/admin/jogos/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local nome = trim(self.params.nome); local players = trim(self.params.players)
  if nome == "" or players == "" then
    self.session.form_erro = "Nome e base de jogadores são obrigatórios."
    return { redirect_to = "/admin/jogos/" .. self.params.id .. "/editar" }
  end
  db.editar_jogo(self.params.id, nome, trim(self.params.genero), players,
    tonumber(self.params.posicao) or 0,
    trim(self.params.descricao), trim(self.params.imagem_url))
  return { redirect_to = "/admin" }
end)

app:post("/admin/jogos/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_jogo(self.params.id)
  return { redirect_to = "/admin" }
end)

return app