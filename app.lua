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
  db.incrementar_views(self.params.id)
  self.noticia         = noticia
  self.comentarios     = db.get_comentarios(self.params.id)
  self.relacionadas    = db.get_noticias_relacionadas(
                           noticia.id, noticia.jogo, noticia.categoria, 4)
  self.jogos_populares = db.get_jogos()          -- já vem ordenado por posicao
  self.mais_vistas     = db.get_mais_vistas(6)   -- top 6 para filtrar a atual na view
  self.erro_coment     = self.session.coment_erro
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
  local items = {}
  for i = 1, math.min(20, #noticias) do table.insert(items, noticias[i]) end
 
  -- Escapa caracteres especiais XML
  local function xml_escape(s)
    s = tostring(s or "")
    s = s:gsub("&",  "&amp;")
    s = s:gsub("<",  "&lt;")
    s = s:gsub(">",  "&gt;")
    s = s:gsub('"',  "&quot;")
    s = s:gsub("'",  "&apos;")
    return s
  end

-- ─── Sitemap.xml ─────────────────────────────────────────────────────────────

app:get("/sitemap.xml", function(self)
  local noticias = db.get_noticias()
  local jogos    = db.get_jogos()
  local base     = "http://localhost:8080"

  -- Páginas estáticas
  local urls_estaticas = {
    { loc = base .. "/",         changefreq = "daily",   priority = "1.0" },
    { loc = base .. "/noticias", changefreq = "daily",   priority = "0.9" },
    { loc = base .. "/ranking",  changefreq = "weekly",  priority = "0.8" },
    { loc = base .. "/sobre",    changefreq = "monthly", priority = "0.5" },
  }

  local linhas = {
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
  }

  -- Páginas estáticas
  for _, u in ipairs(urls_estaticas) do
    table.insert(linhas, "  <url>")
    table.insert(linhas, "    <loc>"        .. u.loc        .. "</loc>")
    table.insert(linhas, "    <changefreq>" .. u.changefreq .. "</changefreq>")
    table.insert(linhas, "    <priority>"   .. u.priority   .. "</priority>")
    table.insert(linhas, "  </url>")
  end

  -- Notícias individuais
  for _, n in ipairs(noticias) do
    table.insert(linhas, "  <url>")
    table.insert(linhas, "    <loc>"        .. base .. "/noticias/" .. n.id .. "</loc>")
    table.insert(linhas, "    <lastmod>"    .. n.criado_em:sub(1, 10)        .. "</lastmod>")
    table.insert(linhas, "    <changefreq>monthly</changefreq>")
    table.insert(linhas, "    <priority>0.7</priority>")
    table.insert(linhas, "  </url>")
  end

  -- Páginas de jogos
  for _, j in ipairs(jogos) do
    -- Encode simples: troca espaços por %20
    local nome_enc = j.nome:gsub(" ", "%%20")
    table.insert(linhas, "  <url>")
    table.insert(linhas, "    <loc>"        .. base .. "/jogos/" .. nome_enc .. "</loc>")
    table.insert(linhas, "    <changefreq>weekly</changefreq>")
    table.insert(linhas, "    <priority>0.6</priority>")
    table.insert(linhas, "  </url>")
  end

  table.insert(linhas, "</urlset>")

  local xml = table.concat(linhas, "\n")
  ngx.header["Content-Type"] = "application/xml; charset=UTF-8"
  return { layout = false, xml }
end)

  -- Lua 5.1 não tem utf8 nativo, um sub corta bytes no meio.
  -- Solução segura: manter as primeiras X palavras ou cortar por espaço
  local function truncar_seguro(s, limite)
    if #s <= limite then return s end
    local sub = s:sub(1, limite)
    -- Remove o último pedaço quebrado que pode ser um multibyte cortado pela metade
    -- Parando sempre em um espaço em branco vazio.
    local ultimo_espaco = sub:match("^(.*%s)")
    return (ultimo_espaco or sub) .. "..."
  end
 
  local linhas = {
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">',
    '  <channel>',
    '    <title>Portal Gamer</title>',
    '    <link>http://localhost:8080</link>',
    '    <description>As últimas notícias do mundo dos games</description>',
    '    <language>pt-BR</language>',
    '    <atom:link href="http://localhost:8080/rss" rel="self" type="application/rss+xml"/>',
  }
 
  for _, n in ipairs(items) do
    table.insert(linhas, '    <item>')
    table.insert(linhas, '      <title>'       .. xml_escape(n.titulo)                   .. '</title>')
    table.insert(linhas, '      <link>'         .. 'http://localhost:8080/noticias/' .. n.id .. '</link>')
    table.insert(linhas, '      <guid>'         .. 'http://localhost:8080/noticias/' .. n.id .. '</guid>')
    table.insert(linhas, '      <pubDate>'      .. xml_escape(n.criado_em)               .. '</pubDate>')
    table.insert(linhas, '      <category>'     .. xml_escape(n.categoria)               .. '</category>')
    table.insert(linhas, '      <description>'  .. xml_escape(truncar_seguro(n.conteudo, 300)) .. '</description>')
    table.insert(linhas, '    </item>')
  end
 
  table.insert(linhas, '  </channel>')
  table.insert(linhas, '</rss>')
 
  local xml = table.concat(linhas, "\n")
 
  local respond_to = require("lapis.application").respond_to

  return respond_to({
    GET = function()
      ngx.header["Content-Type"] = "text/xml; charset=utf-8"
      return { layout = false, xml }
    end
  })(self)
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
  local pag_coment          = tonumber(self.params.pagina_coment) or 1
  local res_coment          = db.get_comentarios_paginado(pag_coment, 10)
  self.comentarios          = res_coment.rows
  self.coment_pagina        = res_coment.pagina
  self.coment_total_pag     = res_coment.total_paginas
  self.coment_total         = res_coment.total
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