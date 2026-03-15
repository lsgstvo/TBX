-- app.lua
local lapis = require("lapis")
local db    = require("db")
local auth  = require("auth")

local function get_leitor_id(self)
   if not self.session.leitor_id then
     self.session.leitor_id = string.format("%x%x", os.time(), math.random(0xFFFF))
   end
   return self.session.leitor_id
 end

local app = lapis.Application()
app.layout = require("views.layout")

-- Lê o webhook do Discord da config (opcional)
-- No config.lua, adicione: config.discord_webhook = "https://discord.com/api/webhooks/..."
 
local config = require("lapis.config").get()

local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end

-- ─── Home ─────────────────────────────────────────────────────────────────────

app:get("/", function(self)
  self.destaques          = db.get_destaques()
  local todas             = db.get_noticias_publicadas()  -- respeita agendamento
  local ids_dest          = {}
  for _, d in ipairs(self.destaques) do ids_dest[d.id] = true end
  local recentes          = {}
  for _, n in ipairs(todas) do
    if not ids_dest[n.id] then
      table.insert(recentes, n)
      if #recentes >= 5 then break end
    end
  end
  self.noticias             = recentes
  self.mais_vistas          = db.get_mais_vistas(5)
  self.jogos_com_noticias   = db.get_jogos_com_noticias(3, 3)
  self.trending_rapido      = db.get_trending_rapido(5)
  self.og_url               = "http://localhost:8080/"
  -- Flash messages
  self.flash_newsletter_msg = self.session.newsletter_msg
  self.session.newsletter_msg = nil
  self.flash_coment_ok = self.session.coment_ok
  self.session.coment_ok = nil
  return { render = "index" }
end)



-- ─── Sobre ────────────────────────────────────────────────────────────────────

app:get("/sobre", function(self)
  self.og_titulo    = "Sobre o Portal Gamer"
  self.og_descricao = "Conheça o Portal Gamer, feito com Lua, Lapis e SQLite."
  self.og_url       = "http://localhost:8080/sobre"
  return { render = "sobre" }
end)

app:get("/about", function(self)
  self.dados        = db.get_dados_about()
  self.og_titulo    = "Sobre o Portal Gamer"
  self.og_descricao = "A história e os números do Portal Gamer."
  self.og_url       = "http://localhost:8080/about"
  return { render = "about" }
end)

app:get("/conquistas", function(self)
  local leitor_id = get_leitor_id(self)
  self.todas_conquistas   = db.get_conquistas_def()
  self.minhas_conquistas  = db.get_conquistas_leitor(leitor_id)
  -- Mapa de desbloqueadas para lookup rápido na view
  self.desbloqueadas = {}
  for _, c in ipairs(self.minhas_conquistas) do
    self.desbloqueadas[c.tipo] = c.desbloqueada_em
  end
  self.og_titulo    = "Minhas Conquistas — Portal Gamer"
  self.og_url       = "http://localhost:8080/conquistas"
  return { render = "conquistas" }
end)

app:get("/mapa", function(self)
  self.noticias   = db.get_noticias_publicadas()
  self.jogos      = db.get_jogos()
  self.categorias = db.get_categorias()
  self.tags_pop   = db.get_tags_populares(20)
  self.autores    = db.get_autores()
  self.lancamentos = db.get_lancamentos(false)
  self.og_titulo    = "Mapa do Site — Portal Gamer"
  self.og_url       = "http://localhost:8080/mapa"
  return { render = "mapa" }
end)

-- ─── Ranking ─────────────────────────────────────────────────────────────────

app:get("/ranking", function(self)
  self.jogos         = db.get_jogos()
  self.og_titulo     = "Ranking de Jogos"
  self.og_descricao  = "Veja o ranking dos jogos mais populares do momento no Portal Gamer."
  self.og_url        = "http://localhost:8080/ranking"
  return { render = "ranking" }
end)


-- ─── Detalhe de Jogo ─────────────────────────────────────────────────────────

app:get("/jogos/:nome", function(self)
  local nome = self.params.nome:gsub("%%20", " "):gsub("+", " ")
  local jogo = db.get_jogo_por_nome(nome)
  if not jogo then return { status = 404, render = "erro" } end
  self.jogo         = jogo
  self.noticias     = db.get_noticias_do_jogo(nome)
  self.og_titulo    = jogo.nome
  self.og_descricao = jogo.descricao ~= "" and jogo.descricao
    or ("Notícias e informações sobre " .. jogo.nome .. " no Portal Gamer.")
  self.og_url       = "http://localhost:8080/jogos/" .. self.params.nome
  self.og_imagem    = jogo.imagem_url ~= "" and jogo.imagem_url or nil
  self.og_tipo      = "article"
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

-- (adiciona registrar_view_diaria e passa autor)
 
-- Adiciona conquistas e views counter
 
app:get("/noticias/:id", function(self)
  local noticia = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  if noticia.publicar_em and noticia.publicar_em ~= ""
    and noticia.publicar_em > os.date("%Y-%m-%d %H:%M:%S") then
    return { status = 404, render = "erro" }
  end
  db.incrementar_views(self.params.id)
  db.registrar_view_diaria(self.params.id)
 
  local ip       = ngx.var.remote_addr or "0.0.0.0"
  local leitor_id = get_leitor_id(self)
 
  -- Incrementa contador de views do leitor na sessão
  self.session.views_total = (self.session.views_total or 0) + 1
  -- Rastreia categorias visitadas
  local cats = self.session.categorias_vistas or {}
  cats[noticia.categoria or ""] = true
  self.session.categorias_vistas = cats
  local n_cats = 0
  for _ in pairs(cats) do n_cats = n_cats + 1 end
 
  -- Verifica conquistas
  local novas_conquistas = db.verificar_conquistas(leitor_id, {
    views_total          = self.session.views_total,
    hora                 = os.date("*t").hour,
    curtidas_total       = self.session.curtidas_total or 0,
    categorias_visitadas = n_cats,
  })
 
  self.noticia          = noticia
  self.autor            = noticia.autor_id and db.get_autor(noticia.autor_id) or nil
  self.comentarios      = db.get_comentarios_aprovados(self.params.id)
  self.relacionadas     = db.get_noticias_relacionadas(
                            noticia.id, noticia.jogo, noticia.categoria, 4)
  self.jogos_populares  = db.get_jogos()
  self.mais_vistas      = db.get_mais_vistas(6)
  self.tags             = db.get_tags_da_noticia(self.params.id)
  self.curtidas         = db.get_curtidas(self.params.id, ip)
  self.novas_conquistas = novas_conquistas   -- para toast JS
  self.modo_leitura     = self.params.leitura == "1"
  self.erro_coment      = self.session.coment_erro
  self.session.coment_erro = nil
  self.flash_coment_ok  = self.session.coment_ok
  self.session.coment_ok = nil
  self.og_titulo    = noticia.titulo
  self.og_descricao = noticia.conteudo:sub(1, 160)
  self.og_url       = "http://localhost:8080/noticias/" .. noticia.id
  self.og_tipo      = "article"
  -- Serializa conquistas novas em JSON para uso no JS da view
  local conquistas_json = "["
  for i, c in ipairs(self.novas_conquistas or {}) do
    conquistas_json = conquistas_json .. string.format(
      '{"nome":%q,"desc":%q,"ico":%q,"cor":%q}%s',
      c.nome, c.desc, c.ico, c.cor,
      i < #self.novas_conquistas and "," or ""
    )
  end
  conquistas_json = conquistas_json .. "]"
  self.conquistas_json = conquistas_json
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
  if #conteudo > 800 then
    self.session.coment_erro = "Comentário muito longo (máx. 800 caracteres)."
    return { redirect_to = "/noticias/" .. self.params.id }
  end
  db.criar_comentario(
    self.params.id,
    autor ~= "" and autor or "Anônimo",
    conteudo
  )
  -- Avisa que está aguardando moderação
  self.session.coment_erro = nil
  self.session.coment_ok   = "Comentário enviado! Ele aparecerá após moderação. ✅"
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

app:get("/busca", function(self)
  self.filtros = {
    termo    = trim(self.params.q       or ""),
    categoria = trim(self.params.categoria or ""),
    jogo      = trim(self.params.jogo    or ""),
    autor_id  = trim(self.params.autor   or ""),
    destaque  = self.params.destaque     or "",
    data_de   = trim(self.params.data_de  or ""),
    data_ate  = trim(self.params.data_ate or ""),
    ordem     = trim(self.params.ordem   or "recente"),
  }
  -- Só busca se tiver pelo menos um filtro preenchido
  local tem_filtro = false
  for _, v in pairs(self.filtros) do
    if v ~= "" and v ~= "recente" then tem_filtro = true; break end
  end
  if tem_filtro then
    self.noticias   = db.busca_avancada(self.filtros)
    self.buscou     = true
  end
  self.categorias = db.get_categorias()
  self.jogos      = db.get_jogos()
  self.autores    = db.get_autores()
  self.og_titulo  = "Busca Avançada"
  self.og_url     = "http://localhost:8080/busca"
  return { render = "busca_avancada" }
end)

app:get("/trending", function(self)
  local janela        = tonumber(self.params.h) or 24
  self.noticias       = db.get_trending(20, janela)
  self.janela         = janela
  self.og_titulo      = "🔥 Trending — Portal Gamer"
  self.og_descricao   = "As notícias mais quentes das últimas " .. janela .. " horas."
  self.og_url         = "http://localhost:8080/trending"
  return { render = "trending" }
end)

app:post("/newsletter/cadastrar", function(self)
  local email    = trim(self.params.email or "")
  local resultado = db.cadastrar_newsletter(email)
  local msgs = {
    ok         = "✅ Cadastrado com sucesso! Você receberá nossas novidades.",
    ja_existe  = "ℹ️ Este e-mail já está cadastrado.",
    reativado  = "✅ Sua inscrição foi reativada!",
    erro       = "❌ E-mail inválido. Verifique e tente novamente.",
  }
  self.session.newsletter_msg = msgs[resultado] or msgs.erro
  -- Redireciona para a página de onde veio (ou home)
  local origem = self.params.origem or "/"
  return { redirect_to = origem }
end)
 
app:get("/newsletter/cancelar", function(self)
  local token = trim(self.params.token or "")
  local ok    = db.cancelar_newsletter(token)
  self.cancelado = ok
  return { render = "newsletter_cancelar" }
end)
 
-- Admin: lista inscritos
app:get("/admin/newsletter", function(self)
  if not auth.require_login(self) then return end
  self.inscritos = db.get_newsletter_inscritos()
  self.total     = db.count_newsletter()
  return { render = "admin.admin_newsletter", layout = "admin.admin_layout" }
end)
 
app:post("/admin/newsletter/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_inscrito(self.params.id)
  return { redirect_to = "/admin/newsletter" }
end)

app:post("/admin/comentarios/:id/aprovar", function(self)
  if not auth.require_login(self) then return end
  db.aprovar_comentario(self.params.id)
  local ref = self.req.headers["referer"] or "/admin"
  return { redirect_to = ref }
end)
 
-- (deletar já existe: POST /admin/comentarios/:id/deletar)

-- Pode ser chamado por um cron: curl -s http://localhost:8080/admin/cron/publicar
-- Protegido por secret na query string
 
app:get("/admin/cron/publicar", function(self)
  local secret = trim(self.params.secret or "")
  if secret ~= (config.cron_secret or "portal_cron_2026") then
    return { status = 403, json = { status = "negado" } }
  end
  local publicadas = db.publicar_agendadas()
  -- Notifica Discord para cada uma (se configurado)
  if publicadas > 0 and config.discord_webhook then
    -- Pega as recém-publicadas (criadas hoje, publicar_em vazio)
    local recentes = db.get_noticias_publicadas()
    for i = 1, math.min(publicadas, #recentes) do
      db.notificar_discord(config.discord_webhook, recentes[i])
    end
  end
  return { json = { status = "ok", publicadas = publicadas } }
end)

app:get("/admin/log", function(self)
  if not auth.require_login(self) then return end
  local pagina   = tonumber(self.params.pagina) or 1
  local resultado = db.get_log(pagina, 25)
  self.log_rows         = resultado.rows
  self.log_pagina       = resultado.pagina
  self.log_total_pag    = resultado.total_paginas
  self.log_total        = resultado.total
  return { render = "admin.admin_log", layout = "admin.admin_layout" }
end)
 
app:get("/admin/noticias/:id/seo", function(self)
  if not auth.require_login(self) then return end
  local noticia = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  self.noticia  = noticia
  self.seo      = db.analisar_seo(noticia)
  return { render = "admin.admin_seo", layout = "admin.admin_layout" }
end)

app:get("/admin/noticias/:id/historico", function(self)
  if not auth.require_login(self) then return end
  local noticia  = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  self.noticia   = noticia
  self.historico = db.get_historico(self.params.id)
  -- Se dois IDs foram passados, faz o diff
  local id_a = tonumber(self.params.a)
  local id_b = tonumber(self.params.b)
  if id_a and id_b then
    self.comparacao = db.comparar_historico(id_a, id_b)
  end
  return { render = "admin.admin_historico_diff", layout = "admin.admin_layout" }
end)


app:post("/admin/log/limpar", function(self)
  if not auth.require_login(self) then return end
  db.limpar_log_antigo(tonumber(self.params.dias) or 90)
  db.log("limpar_log", "log_atividades",
    "Limpou entradas com mais de " .. (self.params.dias or "90") .. " dias",
    ngx.var.remote_addr or "")
  return { redirect_to = "/admin/log" }
end)


app:get("/noticias/:id/pdf", function(self)
  local noticia = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  local autor = noticia.autor_id and db.get_autor(noticia.autor_id) or nil
  local tags  = db.get_tags_da_noticia(self.params.id)
 
  -- Monta lista de tags como string
  local tags_str = ""
  if #tags > 0 then
    local nomes = {}
    for _, t in ipairs(tags) do table.insert(nomes, "#" .. t.nome) end
    tags_str = table.concat(nomes, "  ")
  end
 
  -- Gera HTML que o browser imprime como PDF via window.print()
  local html = string.format([[<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>%s — Portal Gamer</title>
<style>
  @page { margin: 2cm; }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: Georgia, serif; color: #1e293b; line-height: 1.8; font-size: 14px; }
  .header { border-bottom: 3px solid #6366f1; padding-bottom: 16px; margin-bottom: 24px; }
  .brand  { font-size: 13px; color: #6366f1; font-weight: bold; letter-spacing: 1px; text-transform: uppercase; }
  h1      { font-size: 26px; font-weight: bold; margin: 10px 0 8px; color: #0f172a; line-height: 1.3; }
  .meta   { font-size: 12px; color: #64748b; display: flex; gap: 16px; flex-wrap: wrap; margin-bottom: 8px; }
  .tags   { font-size: 12px; color: #6366f1; margin-top: 4px; }
  .img    { width: 100%%; max-height: 300px; object-fit: cover; border-radius: 6px; margin: 20px 0; }
  .corpo  { margin-top: 20px; font-size: 15px; line-height: 1.9; }
  .corpo p { margin-bottom: 14px; text-align: justify; }
  .footer { margin-top: 40px; padding-top: 12px; border-top: 1px solid #cbd5e1;
            font-size: 11px; color: #94a3b8; text-align: center; }
  @media print { .no-print { display: none; } }
</style>
</head>
<body>
<div class="header">
  <div class="brand">🎮 Portal Gamer</div>
  <h1>%s</h1>
  <div class="meta">
    <span>📅 %s</span>
    <span>🗂 %s</span>
    %s
    %s
    <span>👁 %s visualizações</span>
  </div>
  %s
</div>
%s
<div class="corpo"><p>%s</p></div>
<div class="footer">Portal Gamer — localhost:8080 — Gerado em %s</div>
<script class="no-print">window.onload = function(){ window.print(); }</script>
</body></html>]],
    noticia.titulo,
    noticia.titulo,
    noticia.criado_em:sub(1, 10),
    noticia.categoria,
    noticia.jogo ~= "" and ("<span>🎮 " .. noticia.jogo .. "</span>") or "",
    autor and ("<span>✍️ " .. autor.nome .. "</span>") or "",
    tostring(noticia.views or 0),
    tags_str ~= "" and ('<div class="tags">' .. tags_str .. '</div>') or "",
    noticia.imagem_url ~= "" and ('<img class="img" src="http://localhost:8080' .. noticia.imagem_url .. '"/>') or "",
    noticia.conteudo:gsub("\n", "</p><p>"),
    os.date("%d/%m/%Y %H:%M")
  )
 
  ngx.header["Content-Type"] = "text/html; charset=UTF-8"
  return { layout = false, html }
end)


app:get("/tag/:nome", function(self)
  local nome      = self.params.nome
  self.noticias   = db.get_noticias_por_tag(nome)
  self.tag        = nome
  self.categorias = db.get_categorias()
  self.modo_busca = false
  self.pagina     = 1
  self.total_paginas = 1
  self.og_titulo    = "Tag: " .. nome
  self.og_descricao = "Notícias com a tag " .. nome .. " no Portal Gamer."
  self.og_url       = "http://localhost:8080/tag/" .. nome
  return { render = "noticias" }
end)


app:get("/stats", function(self)
  self.stats        = db.get_estatisticas()
  self.og_titulo    = "Estatísticas — Portal Gamer"
  self.og_descricao = "Números e estatísticas do Portal Gamer."
  self.og_url       = "http://localhost:8080/stats"
  return { render = "stats" }
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

app:get("/api/busca", function(self)
  local termo = trim(self.params.q or "")
  if termo == "" then
    return { json = { status = "ok", data = {}, total = 0 } }
  end
  local resultados = db.buscar_noticias(termo)
  -- Retorna só os campos necessários para o dropdown (leve)
  local lite = {}
  for i = 1, math.min(8, #resultados) do
    local n = resultados[i]
    table.insert(lite, {
      id        = n.id,
      titulo    = n.titulo,
      categoria = n.categoria,
      jogo      = n.jogo,
    })
  end
  return { json = { status = "ok", data = lite, total = #lite } }
end)

app:post("/admin/upload/imagem", function(self)
  if not auth.require_login(self) then return end
 
  -- Pega o arquivo enviado via multipart/form-data
  local arquivo = self.params.imagem
  if not arquivo or type(arquivo) ~= "table" then
    return { json = { status = "erro", mensagem = "Nenhum arquivo enviado." } }
  end
 
  -- Valida tipo MIME
  local mime = arquivo.content_type or ""
  local tipos_validos = { ["image/jpeg"] = true, ["image/png"] = true,
                           ["image/gif"]  = true, ["image/webp"] = true }
  if not tipos_validos[mime] then
    return { json = { status = "erro", mensagem = "Tipo de arquivo inválido. Use JPEG, PNG, GIF ou WebP." } }
  end
 
  -- Valida tamanho (máx. 2 MB)
  local conteudo = arquivo.content or ""
  if #conteudo > 2 * 1024 * 1024 then
    return { json = { status = "erro", mensagem = "Arquivo muito grande. Máximo: 2 MB." } }
  end
 
  -- Gera nome único baseado no timestamp
  local extensao_map = {
    ["image/jpeg"] = ".jpg", ["image/png"]  = ".png",
    ["image/gif"]  = ".gif", ["image/webp"] = ".webp",
  }
  local ext      = extensao_map[mime] or ".jpg"
  local nome_arq = tostring(ngx.now()):gsub("%.", "") .. ext
  local caminho  = "static/uploads/" .. nome_arq
 
  -- Garante que o diretório existe
  os.execute("mkdir -p static/uploads")
 
  -- Grava o arquivo
  local f, err = io.open(caminho, "wb")
  if not f then
    return { json = { status = "erro", mensagem = "Erro ao salvar arquivo: " .. (err or "") } }
  end
  f:write(conteudo)
  f:close()
 
  local url = "/static/uploads/" .. nome_arq
  return { json = { status = "ok", url = url, nome = nome_arq } }
end)

app:get("/api/docs", function(self)
  self.og_titulo    = "API — Portal Gamer"
  self.og_descricao = "Documentação da API pública do Portal Gamer."
  self.og_url       = "http://localhost:8080/api/docs"
  return { render = "api_docs" }
end)


app:get("/api/ranking", function(self)
  return { json = { status = "ok", data = db.get_jogos() } }
end)

app:get("/api/busca", function(self)
  local termo = trim(self.params.q or "")
  if termo == "" then
    return { json = { status = "ok", data = {}, total = 0 } }
  end
  local resultados = db.buscar_noticias(termo)
  -- Retorna só os campos necessários para o dropdown (leve)
  local lite = {}
  for i = 1, math.min(8, #resultados) do
    local n = resultados[i]
    table.insert(lite, {
      id        = n.id,
      titulo    = n.titulo,
      categoria = n.categoria,
      jogo      = n.jogo,
    })
  end
  return { json = { status = "ok", data = lite, total = #lite } }
end)

-- Adiciona conquista de curtidor
 
app:post("/api/curtir/:id", function(self)
  local tipo = self.params.tipo
  local ip   = ngx.var.remote_addr or "0.0.0.0"
  if tipo ~= "like" and tipo ~= "dislike" then
    return { json = { status = "erro", mensagem = "Tipo inválido." } }
  end
  local noticia = db.get_noticia(self.params.id)
  if not noticia then
    return { json = { status = "erro", mensagem = "Notícia não encontrada." } }
  end
  local resultado = db.curtir(self.params.id, tipo, ip)
 
  -- Incrementa contador de curtidas na sessão e verifica conquista
  if tipo == "like" then
    self.session.curtidas_total = (self.session.curtidas_total or 0) + 1
    local leitor_id = get_leitor_id(self)
    db.verificar_conquistas(leitor_id, {
      curtidas_total = self.session.curtidas_total
    })
  end
 
  return { json = {
    status   = "ok",
    likes    = resultado.likes,
    dislikes = resultado.dislikes,
    meu_voto = resultado.meu_voto,
  }}
end)


app:post("/admin/upload/imagem", function(self)
  if not auth.require_login(self) then return end
 
  -- Pega o arquivo enviado via multipart/form-data
  local arquivo = self.params.imagem
  if not arquivo or type(arquivo) ~= "table" then
    return { json = { status = "erro", mensagem = "Nenhum arquivo enviado." } }
  end
 
  -- Valida tipo MIME
  local mime = arquivo.content_type or ""
  local tipos_validos = { ["image/jpeg"] = true, ["image/png"] = true,
                           ["image/gif"]  = true, ["image/webp"] = true }
  if not tipos_validos[mime] then
    return { json = { status = "erro", mensagem = "Tipo de arquivo inválido. Use JPEG, PNG, GIF ou WebP." } }
  end
 
  -- Valida tamanho (máx. 2 MB)
  local conteudo = arquivo.content or ""
  if #conteudo > 2 * 1024 * 1024 then
    return { json = { status = "erro", mensagem = "Arquivo muito grande. Máximo: 2 MB." } }
  end
 
  -- Gera nome único baseado no timestamp
  local extensao_map = {
    ["image/jpeg"] = ".jpg", ["image/png"]  = ".png",
    ["image/gif"]  = ".gif", ["image/webp"] = ".webp",
  }
  local ext      = extensao_map[mime] or ".jpg"
  local nome_arq = tostring(ngx.now()):gsub("%.", "") .. ext
  local caminho  = "static/uploads/" .. nome_arq
 
  -- Garante que o diretório existe
  os.execute("mkdir -p static/uploads")
 
  -- Grava o arquivo
  local f, err = io.open(caminho, "wb")
  if not f then
    return { json = { status = "erro", mensagem = "Erro ao salvar arquivo: " .. (err or "") } }
  end
  f:write(conteudo)
  f:close()
 
  local url = "/static/uploads/" .. nome_arq
  return { json = { status = "ok", url = url, nome = nome_arq } }
end)

app:get("/api/docs", function(self)
  self.og_titulo    = "API — Portal Gamer"
  self.og_descricao = "Documentação da API pública do Portal Gamer."
  self.og_url       = "http://localhost:8080/api/docs"
  return { render = "api_docs" }
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
    db.log("login", "admin", self.params.usuario, ngx.var.remote_addr or "")
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

-- (dashboard com views por dia)
 
app:get("/admin", function(self)
  if not auth.require_login(self) then return end
  self.noticias  = db.get_noticias()
  self.jogos     = db.get_jogos()
  local filtro_pend = self.params.pendentes == "1"
  local pag_coment  = tonumber(self.params.pagina_coment) or 1
  local res_coment  = db.get_comentarios_paginado_v2(pag_coment, 10, filtro_pend)
  self.comentarios        = res_coment.rows
  self.coment_pagina      = res_coment.pagina
  self.coment_total_pag   = res_coment.total_paginas
  self.coment_total       = res_coment.total
  self.pendentes_count    = db.count_comentarios_pendentes()
  self.filtro_pendentes   = filtro_pend
  self.views_por_dia      = db.get_views_por_dia(30)
  self.top_semana         = db.get_top_noticias_views(7, 5)
  self.autores            = db.get_autores()
  self.agendadas          = db.get_agendadas()
  self.newsletter_total   = db.count_newsletter()
  return { render = "admin.admin_painel", layout = "admin.admin_layout" }
end)



-- ─── Admin: Notícias ─────────────────────────────────────────────────────────

app:get("/admin/noticias/nova", function(self)
  if not auth.require_login(self) then return end
  self.jogos      = db.get_jogos()
  self.categorias = db.get_categorias()
  self.tags_pop   = db.get_tags_populares(15)
  self.autores    = db.get_autores()         -- novo: lista de autores
  self.erro       = self.session.form_erro
  self.session.form_erro = nil
  return { render = "admin.admin_noticia_form", layout = "admin.admin_layout" }
end)



-- Suporte a agendamento + notificação Discord
 
app:post("/admin/noticias/nova", function(self)
  if not auth.require_login(self) then return end
  local titulo      = trim(self.params.titulo)
  local conteudo    = trim(self.params.conteudo)
  local tags_str    = trim(self.params.tags       or "")
  local imagem_url  = trim(self.params.imagem_url or "")
  local autor_id    = tonumber(self.params.autor_id) or nil
  local publicar_em = trim(self.params.publicar_em or "")
  if titulo == "" or conteudo == "" then
    self.session.form_erro = "Título e conteúdo são obrigatórios."
    return { redirect_to = "/admin/noticias/nova" }
  end
  local id = db.criar_noticia(titulo, conteudo, trim(self.params.jogo),
               trim(self.params.categoria), self.params.destaque == "1")
  if tags_str ~= "" then db.salvar_tags_noticia(id, tags_str) end
  local conn = db.connect()
  conn:exec(string.format(
    "UPDATE noticias SET imagem_url='%s', autor_id=%s, publicar_em='%s' WHERE id=%d",
    imagem_url:gsub("'","''"),
    autor_id and tostring(autor_id) or "NULL",
    publicar_em:gsub("'","''"),
    tonumber(id)
  ))
  db.log("criar_noticia", "noticias", "ID "..id.." — "..titulo, ngx.var.remote_addr or "")
  -- Notificação Discord (só se publicação imediata)
  if publicar_em == "" and config.discord_webhook then
    local noticia = db.get_noticia(id)
    if noticia then db.notificar_discord(config.discord_webhook, noticia) end
  end
  return { redirect_to = "/admin" }
end)



app:get("/admin/noticias/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local noticia = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  self.noticia    = noticia
  self.jogos      = db.get_jogos()
  self.categorias = db.get_categorias()
  self.tags_str   = db.get_tags_string(self.params.id)   -- tags atuais como string
  self.tags_pop   = db.get_tags_populares(15)            -- sugestões
  self.historico  = db.get_historico(self.params.id)     -- histórico de edições
  self.erro       = self.session.form_erro
  self.session.form_erro = nil
  return { render = "admin.admin_noticia_editar", layout = "admin.admin_layout" }
end)


app:post("/admin/noticias/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local titulo     = trim(self.params.titulo)
  local conteudo   = trim(self.params.conteudo)
  local tags_str   = trim(self.params.tags or "")
  local imagem_url = trim(self.params.imagem_url or "")
  local autor_id   = tonumber(self.params.autor_id) or nil
  if titulo == "" or conteudo == "" then
    self.session.form_erro = "Título e conteúdo são obrigatórios."
    return { redirect_to = "/admin/noticias/" .. self.params.id .. "/editar" }
  end
  db.salvar_historico(self.params.id)
  db.editar_noticia(self.params.id, titulo, conteudo,
    trim(self.params.jogo), trim(self.params.categoria),
    self.params.destaque == "1")
  db.salvar_tags_noticia(self.params.id, tags_str)
  local conn = db.connect()
  conn:exec(string.format(
    "UPDATE noticias SET imagem_url='%s', autor_id=%s WHERE id=%d",
    imagem_url:gsub("'","''"),
    autor_id and tostring(autor_id) or "NULL",
    tonumber(self.params.id)
  ))
  db.log("editar_noticia", "noticias", "ID "..self.params.id.." — "..titulo, ngx.var.remote_addr or "")
  db.limpar_historico_antigo(self.params.id, 10)
  return { redirect_to = "/admin" }
end)


app:post("/admin/noticias/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_noticia(self.params.id)
  db.log("deletar_noticia", "noticias", "ID "..self.params.id, ngx.var.remote_addr or "")
  return { redirect_to = "/admin" }
end)

-- ─── Admin: Comentários ───────────────────────────────────────────────────────

app:post("/admin/comentarios/:id/aprovar", function(self)
  if not auth.require_login(self) then return end
  db.aprovar_comentario(self.params.id)
  db.log("aprovar_comentario", "comentarios", "ID "..self.params.id, ngx.var.remote_addr or "")
  return { redirect_to = "/admin#comentarios" }
end)

app:post("/admin/comentarios/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_comentario(self.params.id)
  db.log("deletar_comentario", "comentarios", "ID "..self.params.id, ngx.var.remote_addr or "")
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
    db.log("criar_jogo", "jogos", nome, ngx.var.remote_addr or "")
    return { redirect_to = "/admin/jogos/novo" }
  end
  db.criar_jogo(nome, trim(self.params.genero), players,
    tonumber(self.params.posicao) or 0,
    trim(self.params.descricao), trim(self.params.imagem_url))
  db.log("criar_jogo", "jogos", nome, ngx.var.remote_addr or "")
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

app:get("/admin/api/novos-comentarios", function(self)
  if not auth.require_login(self) then
    return { json = { status = "erro" } }
  end
  local total = db.count_todos_comentarios()
  return { json = { status = "ok", total = total } }
end)

app:get("/admin/autores", function(self)
  if not auth.require_login(self) then return end
  self.autores = db.get_autores()
  return { render = "admin.admin_autores", layout = "admin.admin_layout" }
end)
 
app:get("/admin/autores/novo", function(self)
  if not auth.require_login(self) then return end
  self.erro = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_autor_form", layout = "admin.admin_layout" }
end)
 
app:post("/admin/autores/novo", function(self)
  if not auth.require_login(self) then return end
  local nome = trim(self.params.nome)
  if nome == "" then
    self.session.form_erro = "Nome é obrigatório."
    return { redirect_to = "/admin/autores/novo" }
  end
  db.criar_autor(nome, trim(self.params.bio), trim(self.params.avatar_url))
  return { redirect_to = "/admin/autores" }
end)
 
app:get("/admin/autores/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local autor = db.get_autor(self.params.id)
  if not autor then return { status = 404, render = "erro" } end
  self.autor = autor
  self.erro  = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_autor_editar", layout = "admin.admin_layout" }
end)
 
app:post("/admin/autores/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local nome = trim(self.params.nome)
  if nome == "" then
    self.session.form_erro = "Nome é obrigatório."
    return { redirect_to = "/admin/autores/" .. self.params.id .. "/editar" }
  end
  db.editar_autor(self.params.id, nome, trim(self.params.bio), trim(self.params.avatar_url))
  return { redirect_to = "/admin/autores" }
end)
 
app:post("/admin/autores/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_autor(self.params.id)
  return { redirect_to = "/admin/autores" }
end)
 
app:get("/admin/lancamentos", function(self)
  if not auth.require_login(self) then return end
  self.lancamentos = db.get_lancamentos(false)
  return { render = "admin.admin_lancamentos", layout = "admin.admin_layout" }
end)
 
app:get("/admin/lancamentos/novo", function(self)
  if not auth.require_login(self) then return end
  self.erro = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_lancamento_form", layout = "admin.admin_layout" }
end)
 
app:post("/admin/lancamentos/novo", function(self)
  if not auth.require_login(self) then return end
  local nome = trim(self.params.nome or "")
  if nome == "" then
    self.session.form_erro = "Nome é obrigatório."
    return { redirect_to = "/admin/lancamentos/novo" }
  end
  db.criar_lancamento(nome, trim(self.params.plataformas),
    trim(self.params.data_lancamento), trim(self.params.genero),
    trim(self.params.descricao), trim(self.params.imagem_url),
    trim(self.params.site_url))
  db.log("criar_lancamento", "lancamentos", nome, ngx.var.remote_addr or "")
  return { redirect_to = "/admin/lancamentos" }
end)
 
app:get("/admin/lancamentos/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local lanc = db.get_lancamento(self.params.id)
  if not lanc then return { status = 404, render = "erro" } end
  self.lancamento = lanc
  self.erro = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_lancamento_editar", layout = "admin.admin_layout" }
end)
 
app:post("/admin/lancamentos/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local nome = trim(self.params.nome or "")
  if nome == "" then
    self.session.form_erro = "Nome é obrigatório."
    return { redirect_to = "/admin/lancamentos/" .. self.params.id .. "/editar" }
  end
  db.editar_lancamento(self.params.id, nome, trim(self.params.plataformas),
    trim(self.params.data_lancamento), trim(self.params.genero),
    trim(self.params.descricao), trim(self.params.imagem_url),
    trim(self.params.site_url))
  return { redirect_to = "/admin/lancamentos" }
end)
 
app:post("/admin/lancamentos/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_lancamento(self.params.id)
  return { redirect_to = "/admin/lancamentos" }
end)
 
-- Página pública de lançamentos
app:get("/lancamentos", function(self)
  self.lancamentos  = db.get_lancamentos(false)
  self.og_titulo    = "Próximos Lançamentos"
  self.og_descricao = "Fique por dentro dos próximos jogos."
  self.og_url       = "http://localhost:8080/lancamentos"
  return { render = "lancamentos" }
end)


-- Página pública de um autor
app:get("/autor/:id", function(self)
  local autor = db.get_autor(self.params.id)
  if not autor then return { status = 404, render = "erro" } end
  self.autor    = autor
  self.noticias = db.get_noticias_do_autor(self.params.id)
  self.og_titulo    = autor.nome .. " — Portal Gamer"
  self.og_descricao = autor.bio ~= "" and autor.bio or "Notícias de " .. autor.nome
  self.og_url       = "http://localhost:8080/autor/" .. self.params.id
  return { render = "autor" }
end)

app:post("/jogos/:nome/avaliar", function(self)
  local nome = self.params.nome:gsub("%%20", " "):gsub("+", " ")
  local jogo = db.get_jogo_por_nome(nome)
  if not jogo then return { json = { status = "erro", mensagem = "Jogo não encontrado." } } end
 
  local nota = tonumber(self.params.nota)
  local ip   = ngx.var.remote_addr or "0.0.0.0"
 
  local ok = db.avaliar_jogo(jogo.id, nota, ip)
  if not ok then
    return { json = { status = "erro", mensagem = "Nota inválida." } }
  end
 
  local aval = db.get_avaliacao_jogo(jogo.id)
  return { json = {
    status = "ok",
    media  = aval.media,
    total  = aval.total,
  }}
end)



return app