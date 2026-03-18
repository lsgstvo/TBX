local lapis = require("lapis")
local db    = require("db")
local auth  = require("auth")

local function get_leitor_id(self)
   if not self.session.leitor_id then
     self.session.leitor_id = string.format("%x%x", os.time(), math.random(0xFFFF))
   end
   return self.session.leitor_id
 end

 local function get_leitor_avatar(self)
   local id = get_leitor_id(self)
   local config = db.get_leitor_config(id)
   return config.avatar or '👤'
 end
  local function get_leitor_nome(self)
    local id = get_leitor_id(self)
    local config = db.get_leitor_config(id)
    return config.nome or "Visitante"
  end

-- ─── 0. MIDDLEWARE DE PERFORMANCE ─────────────────────────────────────────
-- Adicione este bloco logo após os requires no app.lua:
--
 local function perf_wrap(rota, fn)
   return function(self)
     local t0 = ngx.now()
     local r  = fn(self)
     local ms = math.floor((ngx.now() - t0) * 1000)
     db.log_perf(rota, ngx.var.request_method or "GET",
                 self.res and self.res.status or 200, ms)
     return r
   end
 end

local app = lapis.Application()
app.layout = require("views.layout")

-- Lê o webhook do Discord da config (opcional)
-- No config.lua, adicione: config.discord_webhook = "https://discord.com/api/webhooks/..."
 
local config = require("lapis.config").get()

local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end

-- Global filter: carrega o avatar, nome e XP em todas as páginas para o header
app:before_filter(function(self)
  local lid = get_leitor_id(self)
  local config = db.get_leitor_config(lid)
  
  self.leitor_icon  = config.avatar or '👤'
  self.leitor_nome  = config.nome   or "Visitante"
  self.leitor_xp    = tonumber(config.xp) or 0
  self.leitor_nivel_info = db.calcular_nivel(self.leitor_xp)
  self.notificacoes_count = db.count_notificacoes_nao_lidas(lid)

  -- Welcome notification for new users
  if self.notificacoes_count == 0 and not self.session.welcome_notif then
    local all_notifs = db.get_notificacoes(lid)
    if #all_notifs == 0 then
      db.criar_notificacao(lid, "Bem-vindo ao Portal Gamer! 🎮", 
        "Agora você receberá notificações sobre suas conquistas e novidades aqui.", "/sobre", "info")
      self.session.welcome_notif = true
      self.notificacoes_count = 1
    end
  end
end)

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

app:get("/perfil", function(self)
  local lid  = get_leitor_id(self)
  local pagina     = tonumber(self.params.pagina) or 1
  local historico  = db.get_historico_leituras(lid, pagina, 12)
  local config = db.get_leitor_config(lid)
 
  self.leitor_id          = lid
  self.historico          = historico.rows
  self.hist_pagina        = historico.pagina
  self.hist_total_pag     = historico.total_paginas
  self.hist_total         = historico.total
  self.conquistas         = db.get_conquistas_leitor(lid)
  self.categorias_pref    = db.get_categorias_preferidas(lid)
  self.views_total        = self.session.views_total or 0
  self.leitor_avatar      = config.avatar
  self.leitor_nome        = config.nome or "Perfil"
  self.leitor_icon        = get_leitor_avatar(self) -- Para o header
  self.favoritos          = db.get_favoritos(lid)
  self.og_titulo          = "Meu Perfil — Portal Gamer"
  self.og_url             = "http://localhost:8080/perfil"
  return { render = "perfil_leitor" }
end)
 
-- Limpa histórico do leitor
app:post("/perfil/limpar", function(self)
  db.limpar_historico_leituras(get_leitor_id(self))
  return { redirect_to = "/perfil" }
end)

-- ─── Notificações ────────────────────────────────────────────────────────────

app:get("/notificacoes", function(self)
  local lid = get_leitor_id(self)
  self.notificacoes     = db.get_notificacoes(lid)
  self.nao_lidas_count  = db.count_notificacoes_nao_lidas(lid)
  self.og_titulo        = "Minhas Notificações — Portal Gamer"
  self.og_url           = "http://localhost:8080/notificacoes"
  return { render = "notificacoes" }
end)

app:post("/notificacoes/:id/lida", function(self)
  db.marcar_lida(self.params.id)
  return { json = { success = true } }
end)

app:post("/notificacoes/ler-todas", function(self)
  db.marcar_todas_lidas(get_leitor_id(self))
  return { redirect_to = "/notificacoes" }
end)

app:post("/notificacoes/limpar", function(self)
  db.limpar_notificacoes(get_leitor_id(self))
  return { redirect_to = "/notificacoes" }
end)

-- Muda avatar do leitor
app:post("/api/perfil/avatar", function(self)
  local lid = get_leitor_id(self)
  local avatar = self.params.avatar
  if avatar then
    db.set_leitor_avatar(lid, avatar)
    return { json = { success = true } }
  end
  return { json = { success = false } }
end)

-- Muda nome do leitor
app:post("/api/perfil/nome", function(self)
  local lid = get_leitor_id(self)
  local nome = self.params.nome
  if nome and #nome > 0 then
    if #nome > 30 then nome = nome:sub(1, 30) end
    db.set_leitor_nome(lid, nome)
    return { json = { success = true, nome = nome } }
  end
  return { json = { success = false } }
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
  local t0      = ngx.now()
  local noticia = db.get_noticia(self.params.id)
  if not noticia then return { status = 404, render = "erro" } end
  if noticia.publicar_em and noticia.publicar_em ~= ""
    and noticia.publicar_em > os.date("%Y-%m-%d %H:%M:%S") then
    return { status = 404, render = "erro" }
  end
  db.incrementar_views(self.params.id)
  db.registrar_view_diaria(self.params.id)
 
  local ip        = ngx.var.remote_addr or "0.0.0.0"
  local leitor_id = get_leitor_id(self)
 
  -- Registra no histórico de leituras
  db.registrar_leitura(leitor_id, self.params.id)
  db.adicionar_xp(leitor_id, "leitura")
 
  self.session.views_total = (self.session.views_total or 0) + 1
  local cats = self.session.categorias_vistas or {}
  cats[noticia.categoria or ""] = true
  self.session.categorias_vistas = cats
  local n_cats = 0
  for _ in pairs(cats) do n_cats = n_cats + 1 end
 
  local novas_conquistas = db.verificar_conquistas(leitor_id, {
    views_total          = self.session.views_total,
    hora                 = os.date("*t").hour,
    curtidas_total       = self.session.curtidas_total or 0,
    categorias_visitadas = n_cats,
  })
 
  for _, c in ipairs(novas_conquistas) do
    db.adicionar_xp(leitor_id, "conquista")
    db.criar_notificacao(leitor_id, "🏆 Nova Conquista!", 
      "Você desbloqueou: " .. c.nome, "/conquistas", "achievement")
  end

  -- Serializa conquistas para JS
  local cjson = {}
  for i, c in ipairs(novas_conquistas) do
    cjson[i] = string.format(
      '{"nome":%q,"desc":%q,"ico":%q,"cor":%q}',
      c.nome, c.desc, c.ico, c.cor
    )
  end
  self.conquistas_json = "[" .. table.concat(cjson, ",") .. "]"
 
  self.noticia         = noticia
  self.autor           = noticia.autor_id and db.get_autor(noticia.autor_id) or nil
  self.comentarios     = db.get_comentarios_aprovados(self.params.id)
  self.relacionadas    = db.get_noticias_relacionadas(
                           noticia.id, noticia.jogo, noticia.categoria, 4)
  self.voce_pode_gostar = db.get_voce_pode_gostar(self.params.id, 4)  -- novo
  self.jogos_populares = db.get_jogos()
  self.mais_vistas     = db.get_mais_vistas(6)
  self.tags            = db.get_tags_da_noticia(self.params.id)
  self.curtidas        = db.get_curtidas(self.params.id, ip)
  self.enquete         = db.get_enquete_da_noticia(self.params.id)    -- novo
  self.ja_votou        = nil  -- verificado no cliente via cookie/IP
  self.modo_leitura    = self.params.leitura == "1"
  self.novas_conquistas = novas_conquistas
  self.erro_coment     = self.session.coment_erro
  self.session.coment_erro = nil
  self.flash_coment_ok = self.session.coment_ok
  self.session.coment_ok = nil
  self.og_titulo    = noticia.titulo
  self.og_descricao = noticia.conteudo:sub(1, 160)
  self.og_url       = "http://localhost:8080/noticias/" .. noticia.id
  self.og_tipo      = "article"
 
  -- Log de performance
  db.log_perf("/noticias/:id", "GET", 200,
    math.floor((ngx.now() - t0) * 1000))
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
  db.adicionar_xp(get_leitor_id(self), "comentario")
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
 
app:get("/admin/performance", function(self)
  if not auth.require_login(self) then return end
  local horas          = tonumber(self.params.h) or 24
  self.stats           = db.get_perf_stats(horas)
  self.por_hora        = db.get_perf_por_hora()
  self.erros_recentes  = db.get_erros_recentes(10)
  self.horas           = horas
  return { render = "admin.admin_performance", layout = "admin.admin_layout" }
end)
 
app:post("/admin/performance/limpar", function(self)
  if not auth.require_login(self) then return end
  db.limpar_perf_log(tonumber(self.params.horas) or 168)
  return { redirect_to = "/admin/performance" }
end)

app:get("/admin/enquetes", function(self)
  if not auth.require_login(self) then return end
  self.enquetes = db.get_enquetes()
  return { render = "admin.admin_enquetes", layout = "admin.admin_layout" }
end)
 
app:get("/admin/enquetes/nova", function(self)
  if not auth.require_login(self) then return end
  self.noticias = db.get_noticias()
  self.erro     = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_enquete_form", layout = "admin.admin_layout" }
end)
 
app:post("/admin/enquetes/nova", function(self)
  if not auth.require_login(self) then return end
  local pergunta   = trim(self.params.pergunta or "")
  local noticia_id = tonumber(self.params.noticia_id) or nil
  if pergunta == "" then
    self.session.form_erro = "A pergunta é obrigatória."
    return { redirect_to = "/admin/enquetes/nova" }
  end
  -- Coleta opções (opcao_1, opcao_2, opcao_3, opcao_4)
  local opcoes = {}
  for i = 1, 6 do
    local op = trim(self.params["opcao_" .. i] or "")
    if op ~= "" then table.insert(opcoes, op) end
  end
  if #opcoes < 2 then
    self.session.form_erro = "Adicione pelo menos 2 opções."
    return { redirect_to = "/admin/enquetes/nova" }
  end
  db.criar_enquete(noticia_id, pergunta, opcoes)
  db.log("criar_enquete", "enquetes", pergunta:sub(1,60), ngx.var.remote_addr or "")
  return { redirect_to = "/admin/enquetes" }
end)
 
app:post("/admin/enquetes/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_enquete(self.params.id)
  return { redirect_to = "/admin/enquetes" }
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
    db.adicionar_xp(leitor_id, "curtida")
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

app:post("/api/enquete/:id/votar", function(self)
  local enquete_id = self.params.id
  local opcao_id   = tonumber(self.params.opcao_id)
  local ip         = ngx.var.remote_addr or "0.0.0.0"
 
  if not opcao_id then
    return { json = { status = "erro", mensagem = "Opção inválida." } }
  end
 
  local resultado = db.votar_enquete(enquete_id, opcao_id, ip)
  if resultado == "ja_votou" then
    return { json = { status = "ja_votou", mensagem = "Você já votou nesta enquete." } }
  end
  if resultado == "erro" then
    return { json = { status = "erro", mensagem = "Opção não encontrada." } }
  end
 
  -- Retorna enquete atualizada
  local enquete = db.get_enquete(enquete_id)
  return { json = { status = "ok", enquete = enquete } }
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

app:get("/comparar", function(self)
  self.jogos = db.get_jogos()
  local id_a = tonumber(self.params.a)
  local id_b = tonumber(self.params.b)
  if id_a and id_b then
    self.comparacao = db.comparar_jogos(id_a, id_b)
    self.id_a       = id_a
    self.id_b       = id_b
  end
  self.og_titulo    = "Comparar Jogos — Portal Gamer"
  self.og_url       = "http://localhost:8080/comparar"
  return { render = "comparar_jogos" }
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



-- ─── Galeria de jogos ─────────────────────────────────────────────────────────

app:get("/galeria", function(self)
  self.jogos          = db.get_jogos()
  self.imagens        = db.get_galeria_todas()
  self.jogo_filtro    = trim(self.params.jogo or "")
  if self.jogo_filtro ~= "" then
    local jogo = db.get_jogo_por_nome(self.jogo_filtro)
    if jogo then
      self.imagens     = db.get_galeria_jogo(jogo.id)
      self.jogo_atual  = jogo
    end
  end
  self.og_titulo    = "Galeria de Jogos — Portal Gamer"
  self.og_url       = "http://localhost:8080/galeria"
  return { render = "galeria" }
end)

app:post("/admin/galeria/adicionar", function(self)
  if not auth.require_login(self) then return end
  local jogo_id = tonumber(self.params.jogo_id)
  local url     = trim(self.params.url or "")
  if not jogo_id or url == "" then
    return { redirect_to = "/admin/galeria" }
  end
  db.adicionar_imagem_galeria(jogo_id, url, trim(self.params.legenda))
  return { redirect_to = "/admin/galeria" }
end)

app:post("/admin/galeria/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_imagem_galeria(self.params.id)
  return { redirect_to = "/admin/galeria" }
end)

app:get("/admin/galeria", function(self)
  if not auth.require_login(self) then return end
  self.imagens = db.get_galeria_todas()
  self.jogos   = db.get_jogos()
  return { render = "admin.admin_galeria", layout = "admin.admin_layout" }
end)

-- ─── Favoritos ────────────────────────────────────────────────────────────────

app:post("/api/favorito/:id", function(self)
  local leitor_id = get_leitor_id(self)
  local noticia   = db.get_noticia(self.params.id)
  if not noticia then
    return { json = { status = "erro", mensagem = "Notícia não encontrada." } }
  end
  local adicionado = db.toggle_favorito(leitor_id, self.params.id)
  if adicionado then db.adicionar_xp(leitor_id, "favorito") end
  return { json = {
    status      = "ok",
    favoritado  = adicionado,
    total       = db.count_favoritos(leitor_id),
  }}
end)

app:get("/favoritos", function(self)
  local leitor_id    = get_leitor_id(self)
  self.favoritos     = db.get_favoritos(leitor_id)
  self.total         = db.count_favoritos(leitor_id)
  self.og_titulo     = "Meus Favoritos — Portal Gamer"
  self.og_url        = "http://localhost:8080/favoritos"
  return { render = "favoritos" }
end)

app:post("/favoritos/limpar", function(self)
  db.limpar_favoritos(get_leitor_id(self))
  return { redirect_to = "/favoritos" }
end)

-- ─── Calendário de agendamento (admin) ───────────────────────────────────────

app:get("/admin/calendario", function(self)
  if not auth.require_login(self) then return end
  local hoje  = os.date("*t")
  local ano   = tonumber(self.params.ano)  or hoje.year
  local mes   = tonumber(self.params.mes)  or hoje.month
  -- Garante limites válidos
  if mes < 1  then mes = 12; ano = ano - 1 end
  if mes > 12 then mes = 1;  ano = ano + 1 end
  self.ano             = ano
  self.mes             = mes
  self.agendadas       = db.get_calendario(ano, mes)
  self.publicadas      = db.get_calendario_publicadas(ano, mes)
  self.hoje_dia        = hoje.day
  self.hoje_mes        = hoje.month
  self.hoje_ano        = hoje.year
  -- Nomes dos meses em português
  local meses_pt = {
    "Janeiro","Fevereiro","Março","Abril","Maio","Junho",
    "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"
  }
  self.mes_nome        = meses_pt[mes]
  -- Dia da semana do 1º do mês (0=dom, 1=seg...)
  local primeiro       = os.time({ year=ano, month=mes, day=1 })
  self.dia_semana_inicio = os.date("*t", primeiro).wday - 1  -- 0=dom
  self.dias_no_mes     = os.date("*t",
    os.time({ year=ano, month=mes+1, day=0 })).day
  -- Monta mapa dia->eventos
  local eventos = {}
  for _, n in ipairs(self.agendadas) do
    local dia = tonumber(n.publicar_em:sub(9,10))
    if dia then
      eventos[dia] = eventos[dia] or {}
      n._tipo = "agendada"
      table.insert(eventos[dia], n)
    end
  end
  for _, n in ipairs(self.publicadas) do
    local dia = tonumber(n.criado_em:sub(9,10))
    if dia then
      eventos[dia] = eventos[dia] or {}
      n._tipo = "publicada"
      table.insert(eventos[dia], n)
    end
  end
  self.eventos = eventos
  return { render = "admin.admin_calendario", layout = "admin.admin_layout" }
end)

-- ─── Glossário ────────────────────────────────────────────────────────────────

app:get("/glossario", function(self)
  local q      = trim(self.params.q or "")
  local letra  = trim(self.params.letra or "")
  if q ~= "" then
    self.termos   = db.buscar_glossario(q)
    self.busca    = q
  elseif letra ~= "" then
    self.termos   = db.get_glossario_por_letra(letra)
    self.letra    = letra
  else
    self.termos   = db.get_glossario()
  end
  -- Letras com conteúdo (para o índice alfabético)
  local todos = db.get_glossario()
  local letras_map = {}
  for _, t in ipairs(todos) do
    local l = t.termo:upper():sub(1,1)
    letras_map[l] = true
  end
  local letras = {}
  for l in pairs(letras_map) do table.insert(letras, l) end
  table.sort(letras)
  self.letras_disponiveis = letras
  self.og_titulo    = "Glossário Gamer"
  self.og_descricao = "Dicionário de termos e jargões do universo dos games."
  self.og_url       = "http://localhost:8080/glossario"
  return { render = "glossario" }
end)

-- ─── Admin: Glossário ─────────────────────────────────────────────────────────

app:get("/admin/glossario", function(self)
  if not auth.require_login(self) then return end
  self.termos = db.get_glossario()
  return { render = "admin.admin_glossario", layout = "admin.admin_layout" }
end)

app:get("/admin/glossario/novo", function(self)
  if not auth.require_login(self) then return end
  self.erro = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_glossario_form", layout = "admin.admin_layout" }
end)

app:post("/admin/glossario/novo", function(self)
  if not auth.require_login(self) then return end
  local termo = trim(self.params.termo or "")
  if termo == "" then
    self.session.form_erro = "Termo é obrigatório."
    return { redirect_to = "/admin/glossario/novo" }
  end
  db.criar_termo(termo, trim(self.params.definicao), trim(self.params.categoria))
  db.log("criar_termo", "glossario", termo, ngx.var.remote_addr or "")
  return { redirect_to = "/admin/glossario" }
end)

app:get("/admin/glossario/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local termo = db.get_termo(self.params.id)
  if not termo then return { status = 404, render = "erro" } end
  self.termo = termo
  self.erro  = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_glossario_editar", layout = "admin.admin_layout" }
end)

app:post("/admin/glossario/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local termo = trim(self.params.termo or "")
  if termo == "" then
    self.session.form_erro = "Termo é obrigatório."
    return { redirect_to = "/admin/glossario/" .. self.params.id .. "/editar" }
  end
  db.editar_termo(self.params.id, termo, trim(self.params.definicao),
    trim(self.params.categoria))
  return { redirect_to = "/admin/glossario" }
end)

app:post("/admin/glossario/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_termo(self.params.id)
  return { redirect_to = "/admin/glossario" }
end)

-- ─── Admin: A/B Test ──────────────────────────────────────────────────────────

app:get("/admin/ab-testes", function(self)
  if not auth.require_login(self) then return end
  self.testes   = db.get_ab_testes()
  self.noticias = db.get_noticias()
  return { render = "admin.admin_ab_testes", layout = "admin.admin_layout" }
end)

app:post("/admin/ab-testes/novo", function(self)
  if not auth.require_login(self) then return end
  local noticia_id = tonumber(self.params.noticia_id)
  local titulo_b   = trim(self.params.titulo_b or "")
  if not noticia_id or titulo_b == "" then
    return { redirect_to = "/admin/ab-testes" }
  end
  db.criar_ab_teste(noticia_id, titulo_b)
  db.log("criar_ab_teste", "ab_testes",
    "Notícia #"..noticia_id.." — "..titulo_b:sub(1,40), ngx.var.remote_addr or "")
  return { redirect_to = "/admin/ab-testes" }
end)

app:post("/admin/ab-testes/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_ab_teste(self.params.id)
  return { redirect_to = "/admin/ab-testes" }
end)

-- API: registra view de variante A/B (chamada via JS invisible pixel)
app:get("/api/ab/:id/:variante", function(self)
  local variante = self.params.variante
  if variante == "a" or variante == "b" then
    db.registrar_view_ab(self.params.id, variante)
  end
  -- Retorna pixel transparente 1x1
  ngx.header["Content-Type"]  = "image/gif"
  ngx.header["Cache-Control"] = "no-store"
  return { layout = false,
    "\x47\x49\x46\x38\x39\x61\x01\x00\x01\x00\x80\x00\x00\xff\xff\xff\x00\x00\x00\x21\xf9\x04\x00\x00\x00\x00\x00\x2c\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02\x44\x01\x00\x3b" }
end)

-- ─── Admin: Citações ──────────────────────────────────────────────────────────

app:get("/admin/citacoes", function(self)
  if not auth.require_login(self) then return end
  self.citacoes = db.get_citacoes()
  return { render = "admin.admin_citacoes", layout = "admin.admin_layout" }
end)

app:post("/admin/citacoes/nova", function(self)
  if not auth.require_login(self) then return end
  local texto = trim(self.params.texto or "")
  if texto == "" then return { redirect_to = "/admin/citacoes" } end
  db.criar_citacao(texto, trim(self.params.personagem), trim(self.params.jogo))
  return { redirect_to = "/admin/citacoes" }
end)

app:post("/admin/citacoes/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_citacao(self.params.id)
  return { redirect_to = "/admin/citacoes" }
end)

-- API: citação aleatória (usada pelo widget do footer via AJAX)
app:get("/api/citacao", function(self)
  local c = db.get_citacao_aleatoria()
  if not c then
    return { json = { status = "vazio" } }
  end
  return { json = {
    status     = "ok",
    texto      = c.texto,
    personagem = c.personagem,
    jogo       = c.jogo,
  }}
end)

-- ─── Feed personalizado ───────────────────────────────────────────────────────

app:get("/feed", function(self)
  local leitor_id   = get_leitor_id(self)
  self.noticias     = db.get_feed_personalizado(leitor_id, 20)
  self.tem_historico = db.get_historico_leituras(leitor_id, 1, 1).total > 0
  self.og_titulo    = "Meu Feed — Portal Gamer"
  self.og_descricao = "Notícias selecionadas para você com base no seu histórico."
  self.og_url       = "http://localhost:8080/feed"
  return { render = "feed_personalizado" }
end)



-- ─── Chat ao vivo ─────────────────────────────────────────────────────────────

-- Polling: retorna mensagens novas após um ID
app:get("/api/chat/:id", function(self)
  local apos = tonumber(self.params.apos) or 0
  local msgs = db.get_chat(self.params.id, apos)
  return { json = { status = "ok", mensagens = msgs, total = #msgs } }
end)

-- Envia mensagem no chat
app:post("/api/chat/:id", function(self)
  local leitor_id = get_leitor_id(self)
  local config    = db.get_leitor_config(leitor_id)
  local mensagem  = trim(self.params.mensagem or "")
  if mensagem == "" then
    return { json = { status = "erro", mensagem = "Mensagem vazia." } }
  end
  if #mensagem > 300 then
    return { json = { status = "erro", mensagem = "Mensagem muito longa (máx. 300 chars)." } }
  end
  local nome   = config.nome   or "Anônimo"
  local avatar = config.avatar or "👤"
  local id = db.enviar_chat(self.params.id, leitor_id, nome, avatar, mensagem)
  -- XP por participação no chat
  db.adicionar_xp(leitor_id, "comentario")
  return { json = { status = "ok", id = id } }
end)

-- ─── XP e Níveis ─────────────────────────────────────────────────────────────

-- Ranking público de XP
app:get("/ranking/xp", function(self)
  self.ranking     = db.get_ranking_xp(50)
  self.niveis_def  = db.get_niveis_def()
  -- Enriquece cada entrada com info de nível
  for _, r in ipairs(self.ranking) do
    local info = db.calcular_nivel(r.xp)
    r.nivel_info = info
  end
  self.og_titulo   = "Ranking de Leitores — Portal Gamer"
  self.og_url      = "http://localhost:8080/ranking/xp"
  return { render = "ranking_xp" }
end)

-- API: XP do leitor atual
app:get("/api/meu-xp", function(self)
  local leitor_id = get_leitor_id(self)
  local config    = db.get_leitor_config(leitor_id)
  local info      = db.calcular_nivel(config.xp or 0)
  return { json = {
    status = "ok",
    xp     = info.xp,
    nivel  = info.nivel,
    proximo = info.proximo,
    pct    = info.pct_proximo,
  }}
end)

-- ─── Torneios de e-sports ─────────────────────────────────────────────────────

app:get("/torneios", function(self)
  self.torneios    = db.get_torneios()
  local leitor_id  = get_leitor_id(self)
  -- Mapa de inscrições do leitor
  self.inscricoes  = {}
  for _, t in ipairs(self.torneios) do
    self.inscricoes[t.id] = db.is_inscrito(t.id, leitor_id)
  end
  self.og_titulo    = "Torneios de E-Sports — Portal Gamer"
  self.og_url       = "http://localhost:8080/torneios"
  return { render = "torneios" }
end)

app:get("/torneios/:id", function(self)
  local torneio   = db.get_torneio(self.params.id)
  if not torneio then return { status = 404, render = "erro" } end
  local leitor_id = get_leitor_id(self)
  self.torneio      = torneio
  self.participantes = db.get_participantes_torneio(self.params.id)
  self.is_inscrito   = db.is_inscrito(self.params.id, leitor_id)
  self.og_titulo     = torneio.nome
  self.og_url        = "http://localhost:8080/torneios/" .. self.params.id
  return { render = "torneio_detalhe" }
end)

app:post("/torneios/:id/inscrever", function(self)
  local leitor_id = get_leitor_id(self)
  local nome_time = trim(self.params.nome_time or "")
  local ok = db.inscrever_torneio(self.params.id, leitor_id, nome_time)
  if ok then db.adicionar_xp(leitor_id, "conquista") end
  return { redirect_to = "/torneios/" .. self.params.id }
end)

-- Admin: CRUD de torneios
app:get("/admin/torneios", function(self)
  if not auth.require_login(self) then return end
  self.torneios = db.get_torneios()
  return { render = "admin.admin_torneios", layout = "admin.admin_layout" }
end)

app:get("/admin/torneios/novo", function(self)
  if not auth.require_login(self) then return end
  self.erro = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_torneio_form", layout = "admin.admin_layout" }
end)

app:post("/admin/torneios/novo", function(self)
  if not auth.require_login(self) then return end
  local nome = trim(self.params.nome or "")
  if nome == "" then
    self.session.form_erro = "Nome é obrigatório."
    return { redirect_to = "/admin/torneios/novo" }
  end
  db.criar_torneio(nome, trim(self.params.jogo), trim(self.params.descricao),
    trim(self.params.premiacao), trim(self.params.data_inicio),
    trim(self.params.data_fim), trim(self.params.imagem_url),
    trim(self.params.status or "upcoming"))
  db.log("criar_torneio", "torneios", nome, ngx.var.remote_addr or "")
  return { redirect_to = "/admin/torneios" }
end)

app:get("/admin/torneios/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local torneio = db.get_torneio(self.params.id)
  if not torneio then return { status = 404, render = "erro" } end
  self.torneio = torneio
  self.erro = self.session.form_erro; self.session.form_erro = nil
  return { render = "admin.admin_torneio_editar", layout = "admin.admin_layout" }
end)

app:post("/admin/torneios/:id/editar", function(self)
  if not auth.require_login(self) then return end
  local nome = trim(self.params.nome or "")
  if nome == "" then
    self.session.form_erro = "Nome é obrigatório."
    return { redirect_to = "/admin/torneios/" .. self.params.id .. "/editar" }
  end
  db.editar_torneio(self.params.id, nome, trim(self.params.jogo),
    trim(self.params.descricao), trim(self.params.premiacao),
    trim(self.params.data_inicio), trim(self.params.data_fim),
    trim(self.params.imagem_url), trim(self.params.status or "upcoming"))
  return { redirect_to = "/admin/torneios" }
end)

app:post("/admin/torneios/:id/deletar", function(self)
  if not auth.require_login(self) then return end
  db.deletar_torneio(self.params.id)
  return { redirect_to = "/admin/torneios" }
end)

-- ─── SEO Global ──────────────────────────────────────────────────────────────

app:get("/admin/seo-global", function(self)
  if not auth.require_login(self) then return end
  local pagina = tonumber(self.params.pagina) or 1
  local ordem  = trim(self.params.ordem or "score_asc")
  local result = db.get_seo_global(pagina, 20, ordem)
  self.noticias     = result.rows
  self.pagina       = result.pagina
  self.total_pag    = result.total_paginas
  self.total        = result.total
  self.ordem        = ordem
  return { render = "admin.admin_seo_global", layout = "admin.admin_layout" }
end)

-- ─── PWA: Service Worker e Manifest ──────────────────────────────────────────

app:get("/manifest.json", function(self)
  ngx.header["Content-Type"] = "application/manifest+json"
  return { layout = false, [[{
  "name": "Portal Gamer",
  "short_name": "PortalGamer",
  "description": "Notícias, rankings e análises do mundo dos games.",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0f172a",
  "theme_color": "#6366f1",
  "orientation": "portrait-primary",
  "icons": [
    { "src": "/static/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any maskable" },
    { "src": "/static/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable" }
  ],
  "categories": ["games", "news", "entertainment"],
  "lang": "pt-BR"
}]] }
end)

app:get("/sw.js", function(self)
  ngx.header["Content-Type"] = "application/javascript"
  ngx.header["Service-Worker-Allowed"] = "/"
  return { layout = false, [[
const CACHE_NAME = 'portal-gamer-v2';
const OFFLINE_URL = '/offline';
const STATIC_ASSETS = [
  '/',
  '/offline',
  '/static/style.css?v=4',
  '/static/icon-192.png',
  '/static/icon-512.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(STATIC_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.map(key => {
        if (key !== CACHE_NAME) return caches.delete(key);
      })
    ))
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);

  // Estratégia Cache-First para arquivos estáticos
  if (url.pathname.startsWith('/static/')) {
    event.respondWith(
      caches.match(event.request).then(cached => {
        return cached || fetch(event.request).then(response => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
          return response;
        });
      })
    );
    return;
  }

  // Estratégia Network-First para páginas HTML (dinâmicas)
  event.respondWith(
    fetch(event.request)
      .then(response => {
        if (response.ok) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        }
        return response;
      })
      .catch(() => {
        return caches.match(event.request).then(cached => {
          return cached || caches.match(OFFLINE_URL);
        });
      })
  );
});
]] }
end)

app:get("/offline", function(self)
  self.og_titulo = "Sem conexão — Portal Gamer"
  return { render = "offline" }
end)


return app