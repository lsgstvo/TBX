-- db.lua
local sqlite3 = require("lsqlite3")

local DB_PATH = "portal_gamer.db"
local db_conn = nil
local M = {}

function M.connect()
  if db_conn then return db_conn end
  db_conn = sqlite3.open(DB_PATH)

  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS noticias (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo     TEXT    NOT NULL,
      conteudo   TEXT    NOT NULL,
      jogo       TEXT    NOT NULL DEFAULT '',
      categoria  TEXT    NOT NULL DEFAULT 'Geral',
      destaque   INTEGER NOT NULL DEFAULT 0,
      views      INTEGER NOT NULL DEFAULT 0,
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  ]])

  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS jogos (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      nome        TEXT    NOT NULL,
      genero      TEXT    NOT NULL DEFAULT '',
      players     TEXT    NOT NULL,
      posicao     INTEGER NOT NULL DEFAULT 0,
      descricao   TEXT    NOT NULL DEFAULT '',
      imagem_url  TEXT    NOT NULL DEFAULT ''
    );
  ]])

  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS categorias (
      id   INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT    NOT NULL UNIQUE
    );
  ]])

  -- Tabela de comentários
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS comentarios (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      noticia_id  INTEGER NOT NULL,
      autor       TEXT    NOT NULL DEFAULT 'Anônimo',
      conteudo    TEXT    NOT NULL,
      criado_em   TEXT    NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (noticia_id) REFERENCES noticias(id) ON DELETE CASCADE
    );
  ]])

-- Tags
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS tags (
      id   INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT    NOT NULL UNIQUE
    );
  ]])
 
  -- Relação notícia <-> tags (many-to-many)
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS noticia_tags (
      noticia_id INTEGER NOT NULL,
      tag_id     INTEGER NOT NULL,
      PRIMARY KEY (noticia_id, tag_id),
      FOREIGN KEY (noticia_id) REFERENCES noticias(id) ON DELETE CASCADE,
      FOREIGN KEY (tag_id)     REFERENCES tags(id)     ON DELETE CASCADE
    );
  ]])
 
  -- Histórico de edições
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS historico_edicoes (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      noticia_id  INTEGER NOT NULL,
      titulo_ant  TEXT    NOT NULL,
      conteudo_ant TEXT   NOT NULL,
      editado_em  TEXT    NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (noticia_id) REFERENCES noticias(id) ON DELETE CASCADE
    );
  ]])

  -- Também adicione a coluna imagem_url nas notícias:
  db_conn:exec("ALTER TABLE noticias ADD COLUMN imagem_url TEXT NOT NULL DEFAULT ''")

  -- Autores
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS autores (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      nome       TEXT    NOT NULL,
      bio        TEXT    NOT NULL DEFAULT '',
      avatar_url TEXT    NOT NULL DEFAULT '',
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  ]])
 
  -- Migração: coluna autor_id nas notícias
  db_conn:exec("ALTER TABLE noticias ADD COLUMN autor_id INTEGER REFERENCES autores(id)")
 
  -- Avaliações dos jogos (1 avaliação por IP por jogo)
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS avaliacoes (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      jogo_id    INTEGER NOT NULL,
      nota       INTEGER NOT NULL CHECK(nota BETWEEN 1 AND 5),
      ip         TEXT    NOT NULL DEFAULT '',
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now')),
      UNIQUE(jogo_id, ip),
      FOREIGN KEY (jogo_id) REFERENCES jogos(id) ON DELETE CASCADE
    );
  ]])
 
  -- Registro diário de views por notícia (para o gráfico do dashboard)
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS views_diarias (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      noticia_id INTEGER NOT NULL,
      data       TEXT    NOT NULL,
      total      INTEGER NOT NULL DEFAULT 0,
      UNIQUE(noticia_id, data),
      FOREIGN KEY (noticia_id) REFERENCES noticias(id) ON DELETE CASCADE
    );
  ]])


  -- Migrações seguras para bancos já existentes
  db_conn:exec("ALTER TABLE noticias ADD COLUMN categoria  TEXT    NOT NULL DEFAULT 'Geral'")
  db_conn:exec("ALTER TABLE noticias ADD COLUMN destaque   INTEGER NOT NULL DEFAULT 0")
  db_conn:exec("ALTER TABLE noticias ADD COLUMN views      INTEGER NOT NULL DEFAULT 0")
  db_conn:exec("ALTER TABLE jogos    ADD COLUMN descricao  TEXT    NOT NULL DEFAULT ''")
  db_conn:exec("ALTER TABLE jogos    ADD COLUMN imagem_url TEXT    NOT NULL DEFAULT ''")

 -- Newsletter: cadastros de e-mail
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS newsletter (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      email      TEXT    NOT NULL UNIQUE,
      ativo      INTEGER NOT NULL DEFAULT 1,
      token      TEXT    NOT NULL DEFAULT '',
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  ]])
 
  -- Moderação: adiciona coluna aprovado nos comentários
  db_conn:exec("ALTER TABLE comentarios ADD COLUMN aprovado INTEGER NOT NULL DEFAULT 0")
 
  -- Agendamento: adiciona coluna publicar_em nas notícias
  db_conn:exec("ALTER TABLE noticias ADD COLUMN publicar_em TEXT NOT NULL DEFAULT ''")


  -- Categorias padrão
  for _, c in ipairs({ "Geral", "Update", "Lançamento", "E-Sports", "Hardware", "Indie" }) do
    db_conn:exec(string.format("INSERT OR IGNORE INTO categorias (nome) VALUES ('%s')", c))
  end

  return db_conn
end

function M.close()
  if db_conn then db_conn:close(); db_conn = nil end
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function query(sql)
  local conn = M.connect()
  local rows = {}
  for row in conn:nrows(sql) do table.insert(rows, row) end
  return rows
end

local function escape(val)
  if val == nil then return "NULL" end
  if type(val) == "number" then return tostring(val) end
  return "'" .. tostring(val):gsub("'", "''") .. "'"
end

-- ─── Categorias ──────────────────────────────────────────────────────────────

function M.get_categorias()
  return query("SELECT * FROM categorias ORDER BY nome ASC")
end

function M.get_noticias_por_categoria(categoria)
  return query(string.format(
    "SELECT * FROM noticias WHERE categoria = %s ORDER BY destaque DESC, criado_em DESC",
    escape(categoria)
  ))
end

-- ─── Notícias ────────────────────────────────────────────────────────────────

function M.get_noticias()
  return query("SELECT * FROM noticias ORDER BY destaque DESC, criado_em DESC")
end

function M.get_destaques()
  return query("SELECT * FROM noticias WHERE destaque = 1 ORDER BY criado_em DESC")
end

-- Mais vistas (para sidebar ou widget)
function M.get_mais_vistas(limite)
  return query(string.format(
    "SELECT * FROM noticias ORDER BY views DESC LIMIT %d", tonumber(limite) or 5
  ))
end

function M.get_noticias_paginado(pagina, por_pagina, categoria)
  pagina     = tonumber(pagina)     or 1
  por_pagina = tonumber(por_pagina) or 6
  local where = ""
  if categoria and categoria ~= "" then
    where = string.format("WHERE categoria = %s", escape(categoria))
  end
  local total  = query("SELECT COUNT(*) as total FROM noticias " .. where)[1].total
  local offset = (pagina - 1) * por_pagina
  local rows   = query(string.format(
    "SELECT * FROM noticias %s ORDER BY destaque DESC, criado_em DESC LIMIT %d OFFSET %d",
    where, por_pagina, offset
  ))
  return {
    rows = rows, total = total, pagina = pagina,
    por_pagina = por_pagina, total_paginas = math.ceil(total / por_pagina),
    categoria = categoria or "",
  }
end

function M.buscar_noticias(termo)
  local t = escape("%" .. (termo or "") .. "%")
  return query(string.format(
    "SELECT * FROM noticias WHERE titulo LIKE %s OR jogo LIKE %s OR categoria LIKE %s ORDER BY destaque DESC, criado_em DESC",
    t, t, t
  ))
end

function M.get_noticia(id)
  local rows = query("SELECT * FROM noticias WHERE id = " .. tonumber(id))
  return rows[1]
end

-- Incrementa o contador de views
function M.incrementar_views(id)
  local conn = M.connect()
  conn:exec("UPDATE noticias SET views = views + 1 WHERE id = " .. tonumber(id))
end

function M.criar_noticia(titulo, conteudo, jogo, categoria, destaque)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO noticias (titulo, conteudo, jogo, categoria, destaque) VALUES (%s,%s,%s,%s,%d)",
    escape(titulo), escape(conteudo), escape(jogo or ""),
    escape(categoria or "Geral"), destaque and 1 or 0
  ))
  return conn:last_insert_rowid()
end

function M.editar_noticia(id, titulo, conteudo, jogo, categoria, destaque)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE noticias SET titulo=%s,conteudo=%s,jogo=%s,categoria=%s,destaque=%d WHERE id=%d",
    escape(titulo), escape(conteudo), escape(jogo or ""),
    escape(categoria or "Geral"), destaque and 1 or 0, tonumber(id)
  ))
end

function M.deletar_noticia(id)
  local conn = M.connect()
  conn:exec("DELETE FROM noticias WHERE id = " .. tonumber(id))
end

-- ─── Comentários ─────────────────────────────────────────────────────────────

-- Retorna todos os comentários aprovados de uma notícia
function M.get_comentarios(noticia_id)
  return query(string.format(
    "SELECT * FROM comentarios WHERE noticia_id = %d ORDER BY criado_em ASC",
    tonumber(noticia_id)
  ))
end

-- Conta comentários de uma notícia
function M.count_comentarios(noticia_id)
  local r = query(string.format(
    "SELECT COUNT(*) as total FROM comentarios WHERE noticia_id = %d",
    tonumber(noticia_id)
  ))
  return r[1] and r[1].total or 0
end

-- Insere um novo comentário
function M.criar_comentario(noticia_id, autor, conteudo)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO comentarios (noticia_id, autor, conteudo) VALUES (%d, %s, %s)",
    tonumber(noticia_id), escape(autor or "Anônimo"), escape(conteudo)
  ))
  return conn:last_insert_rowid()
end

-- Remove um comentário (usado pelo admin)
function M.deletar_comentario(id)
  local conn = M.connect()
  conn:exec("DELETE FROM comentarios WHERE id = " .. tonumber(id))
end

-- Todos os comentários (para painel admin)
function M.get_todos_comentarios()
  return query([[
    SELECT c.*, n.titulo as noticia_titulo
    FROM comentarios c
    JOIN noticias n ON c.noticia_id = n.id
    ORDER BY c.criado_em DESC
  ]])
end

-- ─── Jogos ───────────────────────────────────────────────────────────────────

function M.get_jogos()
  return query("SELECT * FROM jogos ORDER BY posicao ASC")
end

function M.get_jogo(id)
  local rows = query("SELECT * FROM jogos WHERE id = " .. tonumber(id))
  return rows[1]
end

function M.get_jogo_por_nome(nome)
  local rows = query(string.format(
    "SELECT * FROM jogos WHERE nome = %s LIMIT 1", escape(nome)
  ))
  return rows[1]
end

function M.get_noticias_do_jogo(nome_jogo)
  return query(string.format(
    "SELECT * FROM noticias WHERE jogo = %s ORDER BY destaque DESC, criado_em DESC",
    escape(nome_jogo)
  ))
end

function M.criar_jogo(nome, genero, players, posicao, descricao, imagem_url)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO jogos (nome,genero,players,posicao,descricao,imagem_url) VALUES (%s,%s,%s,%s,%s,%s)",
    escape(nome), escape(genero or ""), escape(players),
    escape(tonumber(posicao) or 0), escape(descricao or ""), escape(imagem_url or "")
  ))
  return conn:last_insert_rowid()
end

function M.editar_jogo(id, nome, genero, players, posicao, descricao, imagem_url)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE jogos SET nome=%s,genero=%s,players=%s,posicao=%s,descricao=%s,imagem_url=%s WHERE id=%d",
    escape(nome), escape(genero or ""), escape(players),
    escape(tonumber(posicao) or 0), escape(descricao or ""), escape(imagem_url or ""),
    tonumber(id)
  ))
end

function M.deletar_jogo(id)
  local conn = M.connect()
  conn:exec("DELETE FROM jogos WHERE id = " .. tonumber(id))
end

-- ─── Notícias relacionadas ────────────────────────────────────────────────────
-- Busca até `limite` notícias do mesmo jogo ou categoria, excluindo a atual

function M.get_noticias_relacionadas(noticia_id, jogo, categoria, limite)
  local conn  = M.connect()
  limite      = tonumber(limite) or 4
  noticia_id  = tonumber(noticia_id)
  local rows  = {}

  -- 1ª prioridade: mesmo jogo
  if jogo and jogo ~= "" then
    local sql = string.format(
      "SELECT * FROM noticias WHERE jogo = %s AND id != %d ORDER BY criado_em DESC LIMIT %d",
      escape(jogo), noticia_id, limite
    )
    for row in conn:nrows(sql) do table.insert(rows, row) end
  end

  -- 2ª prioridade: mesma categoria (completa até o limite)
  if #rows < limite and categoria and categoria ~= "" then
    local ja = {}
    for _, r in ipairs(rows) do ja[r.id] = true end
    local faltam = limite - #rows
    local sql = string.format(
      "SELECT * FROM noticias WHERE categoria = %s AND id != %d ORDER BY criado_em DESC LIMIT %d",
      escape(categoria), noticia_id, faltam * 2  -- busca mais para filtrar duplicatas
    )
    for row in conn:nrows(sql) do
      if not ja[row.id] then
        table.insert(rows, row)
        if #rows >= limite then break end
      end
    end
  end

  return rows
end

-- ─── Comentários paginados (para o admin) ─────────────────────────────────────

function M.get_comentarios_paginado(pagina, por_pagina)
  pagina     = tonumber(pagina)     or 1
  por_pagina = tonumber(por_pagina) or 10
  local total  = query("SELECT COUNT(*) as total FROM comentarios")[1].total
  local offset = (pagina - 1) * por_pagina
  local rows   = query(string.format([[
    SELECT c.*, n.titulo as noticia_titulo
    FROM comentarios c
    JOIN noticias n ON c.noticia_id = n.id
    ORDER BY c.criado_em DESC
    LIMIT %d OFFSET %d
  ]], por_pagina, offset))
  return {
    rows          = rows,
    total         = total,
    pagina        = pagina,
    por_pagina    = por_pagina,
    total_paginas = math.ceil(total / por_pagina),
  }
end

-- Conta total de comentários (usado pela notificação do admin)
function M.count_todos_comentarios()
  local r = query("SELECT COUNT(*) as total FROM comentarios")
  return r[1] and r[1].total or 0
end

-- Retorna todas as tags ordenadas por nome
function M.get_tags()
  return query("SELECT * FROM tags ORDER BY nome ASC")
end
 
-- Retorna as tags de uma notícia
function M.get_tags_da_noticia(noticia_id)
  return query(string.format([[
    SELECT t.* FROM tags t
    INNER JOIN noticia_tags nt ON nt.tag_id = t.id
    WHERE nt.noticia_id = %d
    ORDER BY t.nome ASC
  ]], tonumber(noticia_id)))
end
 
-- Retorna notícias que têm uma tag específica
function M.get_noticias_por_tag(tag_nome)
  return query(string.format([[
    SELECT n.* FROM noticias n
    INNER JOIN noticia_tags nt ON nt.noticia_id = n.id
    INNER JOIN tags t ON t.id = nt.tag_id
    WHERE t.nome = %s
    ORDER BY n.destaque DESC, n.criado_em DESC
  ]], escape(tag_nome)))
end
 
-- Cria uma tag se ainda não existir; retorna o id
function M.garantir_tag(nome)
  local conn = M.connect()
  nome = nome:match("^%s*(.-)%s*$")  -- trim
  if nome == "" then return nil end
  conn:exec(string.format("INSERT OR IGNORE INTO tags (nome) VALUES (%s)", escape(nome)))
  local rows = query(string.format("SELECT id FROM tags WHERE nome = %s LIMIT 1", escape(nome)))
  return rows[1] and rows[1].id or nil
end
 
-- Salva as tags de uma notícia (substitui todas as anteriores)
-- tags_str: string separada por vírgulas, ex: "action,fps,ranked"
function M.salvar_tags_noticia(noticia_id, tags_str)
  local conn = M.connect()
  noticia_id = tonumber(noticia_id)
  -- Remove todas as tags antigas da notícia
  conn:exec("DELETE FROM noticia_tags WHERE noticia_id = " .. noticia_id)
  if not tags_str or tags_str == "" then return end
  -- Processa cada tag
  for tag in tags_str:gmatch("[^,]+") do
    local nome = tag:match("^%s*(.-)%s*$"):lower()
    if nome ~= "" then
      local tag_id = M.garantir_tag(nome)
      if tag_id then
        conn:exec(string.format(
          "INSERT OR IGNORE INTO noticia_tags (noticia_id, tag_id) VALUES (%d, %d)",
          noticia_id, tag_id
        ))
      end
    end
  end
end
 
-- Retorna tags como string "tag1,tag2,tag3" (para preencher o input de edição)
function M.get_tags_string(noticia_id)
  local tags = M.get_tags_da_noticia(noticia_id)
  local nomes = {}
  for _, t in ipairs(tags) do table.insert(nomes, t.nome) end
  return table.concat(nomes, ", ")
end
 
-- Tags mais usadas (para sugestões / nuvem)
function M.get_tags_populares(limite)
  return query(string.format([[
    SELECT t.nome, COUNT(nt.noticia_id) as total
    FROM tags t
    INNER JOIN noticia_tags nt ON nt.tag_id = t.id
    GROUP BY t.id
    ORDER BY total DESC
    LIMIT %d
  ]], tonumber(limite) or 20))
end
 
-- ─── Histórico de edições ─────────────────────────────────────────────────────
 
-- Salva snapshot ANTES de editar (chame antes de editar_noticia)
function M.salvar_historico(noticia_id)
  local conn    = M.connect()
  local noticia = M.get_noticia(noticia_id)
  if not noticia then return end
  conn:exec(string.format(
    "INSERT INTO historico_edicoes (noticia_id, titulo_ant, conteudo_ant) VALUES (%d, %s, %s)",
    tonumber(noticia_id), escape(noticia.titulo), escape(noticia.conteudo)
  ))
end
 
-- Retorna o histórico de uma notícia
function M.get_historico(noticia_id)
  return query(string.format(
    "SELECT * FROM historico_edicoes WHERE noticia_id = %d ORDER BY editado_em DESC",
    tonumber(noticia_id)
  ))
end
 
-- Remove histórico antigo (mantém só os últimos N registros por notícia)
function M.limpar_historico_antigo(noticia_id, manter)
  local conn = M.connect()
  manter     = tonumber(manter) or 10
  conn:exec(string.format([[
    DELETE FROM historico_edicoes
    WHERE noticia_id = %d
      AND id NOT IN (
        SELECT id FROM historico_edicoes
        WHERE noticia_id = %d
        ORDER BY editado_em DESC
        LIMIT %d
      )
  ]], tonumber(noticia_id), tonumber(noticia_id), manter))
end
 
-- ─── Estatísticas do portal ───────────────────────────────────────────────────
 
function M.get_estatisticas()
  local conn = M.connect()
 
  local total_noticias  = query("SELECT COUNT(*) as n FROM noticias")[1].n
  local total_jogos     = query("SELECT COUNT(*) as n FROM jogos")[1].n
  local total_coments   = query("SELECT COUNT(*) as n FROM comentarios")[1].n
  local total_views     = query("SELECT COALESCE(SUM(views),0) as n FROM noticias")[1].n
  local total_tags      = query("SELECT COUNT(*) as n FROM tags")[1].n
  local total_destaques = query("SELECT COUNT(*) as n FROM noticias WHERE destaque=1")[1].n
 
  -- Notícia mais vista
  local mais_vista = query(
    "SELECT id, titulo, views FROM noticias ORDER BY views DESC LIMIT 1"
  )[1]
 
  -- Top 5 jogos por número de notícias
  local top_jogos = query([[
    SELECT jogo, COUNT(*) as total
    FROM noticias WHERE jogo != ''
    GROUP BY jogo ORDER BY total DESC LIMIT 5
  ]])
 
  -- Top 5 categorias por número de notícias
  local top_categorias = query([[
    SELECT categoria, COUNT(*) as total
    FROM noticias
    GROUP BY categoria ORDER BY total DESC LIMIT 5
  ]])
 
  -- Notícias por mês (últimos 6 meses)
  local por_mes = query([[
    SELECT strftime('%Y-%m', criado_em) as mes, COUNT(*) as total
    FROM noticias
    GROUP BY mes ORDER BY mes DESC LIMIT 6
  ]])
 
  -- Tags mais usadas
  local top_tags = query([[
    SELECT t.nome, COUNT(nt.noticia_id) as total
    FROM tags t INNER JOIN noticia_tags nt ON nt.tag_id = t.id
    GROUP BY t.id ORDER BY total DESC LIMIT 8
  ]])
 
  return {
    total_noticias  = total_noticias,
    total_jogos     = total_jogos,
    total_coments   = total_coments,
    total_views     = total_views,
    total_tags      = total_tags,
    total_destaques = total_destaques,
    mais_vista      = mais_vista,
    top_jogos       = top_jogos,
    top_categorias  = top_categorias,
    por_mes         = por_mes,
    top_tags        = top_tags,
  }
end
 
-- ─── Notícias por jogo (widget home) ─────────────────────────────────────────
 
-- Retorna os N jogos que têm mais notícias + as últimas notícias de cada
function M.get_jogos_com_noticias(limite_jogos, noticias_por_jogo)
  limite_jogos       = tonumber(limite_jogos)       or 3
  noticias_por_jogo  = tonumber(noticias_por_jogo)  or 3
 
  -- Jogos com mais notícias (entre os cadastrados no ranking)
  local jogos = query(string.format([[
    SELECT j.nome, j.imagem_url, COUNT(n.id) as total
    FROM jogos j
    LEFT JOIN noticias n ON n.jogo = j.nome
    GROUP BY j.nome
    ORDER BY total DESC, j.posicao ASC
    LIMIT %d
  ]], limite_jogos))
 
  -- Para cada jogo, busca as últimas notícias
  for _, j in ipairs(jogos) do
    j.noticias = query(string.format(
      "SELECT id, titulo, criado_em FROM noticias WHERE jogo = %s ORDER BY criado_em DESC LIMIT %d",
      escape(j.nome), noticias_por_jogo
    ))
  end
 
  return jogos
end

-- Contém: autores, avaliações de jogos, views por dia, busca avançada
 

 
-- ─── Autores ─────────────────────────────────────────────────────────────────
 
function M.get_autores()
  return query("SELECT * FROM autores ORDER BY nome ASC")
end
 
function M.get_autor(id)
  local rows = query("SELECT * FROM autores WHERE id = " .. tonumber(id))
  return rows[1]
end
 
function M.criar_autor(nome, bio, avatar_url)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO autores (nome, bio, avatar_url) VALUES (%s, %s, %s)",
    escape(nome), escape(bio or ""), escape(avatar_url or "")
  ))
  return conn:last_insert_rowid()
end
 
function M.editar_autor(id, nome, bio, avatar_url)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE autores SET nome=%s, bio=%s, avatar_url=%s WHERE id=%d",
    escape(nome), escape(bio or ""), escape(avatar_url or ""), tonumber(id)
  ))
end
 
function M.deletar_autor(id)
  local conn = M.connect()
  conn:exec("DELETE FROM autores WHERE id = " .. tonumber(id))
end
 
-- Notícias de um autor específico
function M.get_noticias_do_autor(autor_id)
  return query(string.format(
    "SELECT * FROM noticias WHERE autor_id = %d ORDER BY criado_em DESC",
    tonumber(autor_id)
  ))
end
 
-- ─── Views diárias ───────────────────────────────────────────────────────────
 
-- Chame isso em vez de (ou junto com) incrementar_views
function M.registrar_view_diaria(noticia_id)
  local conn = M.connect()
  local hoje = os.date("%Y-%m-%d")
  -- INSERT OR IGNORE cria o registro; UPDATE incrementa
  conn:exec(string.format(
    "INSERT OR IGNORE INTO views_diarias (noticia_id, data, total) VALUES (%d, '%s', 0)",
    tonumber(noticia_id), hoje
  ))
  conn:exec(string.format(
    "UPDATE views_diarias SET total = total + 1 WHERE noticia_id = %d AND data = '%s'",
    tonumber(noticia_id), hoje
  ))
end
 
-- Views totais por dia (últimos N dias) — para o gráfico do dashboard
function M.get_views_por_dia(dias)
  dias = tonumber(dias) or 30
  return query(string.format([[
    SELECT data, SUM(total) as total
    FROM views_diarias
    WHERE data >= date('now', '-%d days')
    GROUP BY data
    ORDER BY data ASC
  ]], dias))
end
 
-- Views por notícia nos últimos N dias
function M.get_top_noticias_views(dias, limite)
  dias   = tonumber(dias)   or 7
  limite = tonumber(limite) or 5
  return query(string.format([[
    SELECT n.id, n.titulo, SUM(v.total) as views_periodo
    FROM views_diarias v
    JOIN noticias n ON n.id = v.noticia_id
    WHERE v.data >= date('now', '-%d days')
    GROUP BY n.id
    ORDER BY views_periodo DESC
    LIMIT %d
  ]], dias, limite))
end
 
-- ─── Avaliações de jogos ─────────────────────────────────────────────────────
 
-- Retorna nota média e total de avaliações de um jogo
function M.get_avaliacao_jogo(jogo_id)
  local rows = query(string.format([[
    SELECT
      ROUND(AVG(nota), 1) as media,
      COUNT(*) as total
    FROM avaliacoes
    WHERE jogo_id = %d
  ]], tonumber(jogo_id)))
  return rows[1] or { media = 0, total = 0 }
end
 
-- Verifica se um IP já avaliou este jogo
function M.ip_ja_avaliou(jogo_id, ip)
  local rows = query(string.format(
    "SELECT id FROM avaliacoes WHERE jogo_id = %d AND ip = %s LIMIT 1",
    tonumber(jogo_id), escape(ip)
  ))
  return #rows > 0
end
 
-- Salva ou atualiza avaliação (INSERT OR REPLACE)
function M.avaliar_jogo(jogo_id, nota, ip)
  nota = tonumber(nota)
  if not nota or nota < 1 or nota > 5 then return false end
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT OR REPLACE INTO avaliacoes (jogo_id, nota, ip) VALUES (%d, %d, %s)",
    tonumber(jogo_id), nota, escape(ip)
  ))
  return true
end
 
-- Distribuição das notas de um jogo (para o breakdown visual)
function M.get_distribuicao_notas(jogo_id)
  return query(string.format([[
    SELECT nota, COUNT(*) as total
    FROM avaliacoes WHERE jogo_id = %d
    GROUP BY nota ORDER BY nota DESC
  ]], tonumber(jogo_id)))
end
 
-- Média de todos os jogos (para o ranking)
function M.get_medias_jogos()
  return query([[
    SELECT j.id, j.nome,
      ROUND(AVG(a.nota), 1) as media,
      COUNT(a.id) as total_avals
    FROM jogos j
    LEFT JOIN avaliacoes a ON a.jogo_id = j.id
    GROUP BY j.id
    ORDER BY j.posicao ASC
  ]])
end
 
-- ─── Busca avançada ───────────────────────────────────────────────────────────
 
-- Filtros: termo, categoria, jogo, autor_id, destaque, data_de, data_ate, ordem
function M.busca_avancada(filtros)
  local wheres = {}
  local f = filtros or {}
 
  if f.termo and f.termo ~= "" then
    local t = escape("%" .. f.termo .. "%")
    table.insert(wheres, string.format(
      "(n.titulo LIKE %s OR n.conteudo LIKE %s)", t, t
    ))
  end
  if f.categoria and f.categoria ~= "" then
    table.insert(wheres, string.format("n.categoria = %s", escape(f.categoria)))
  end
  if f.jogo and f.jogo ~= "" then
    table.insert(wheres, string.format("n.jogo = %s", escape(f.jogo)))
  end
  if f.autor_id and f.autor_id ~= "" then
    table.insert(wheres, string.format("n.autor_id = %d", tonumber(f.autor_id)))
  end
  if f.destaque == "1" then
    table.insert(wheres, "n.destaque = 1")
  end
  if f.data_de and f.data_de ~= "" then
    table.insert(wheres, string.format("n.criado_em >= %s", escape(f.data_de)))
  end
  if f.data_ate and f.data_ate ~= "" then
    table.insert(wheres, string.format("n.criado_em <= %s", escape(f.data_ate .. " 23:59:59")))
  end
 
  local where_sql = #wheres > 0
    and ("WHERE " .. table.concat(wheres, " AND "))
    or ""
 
  local ordem_map = {
    recente  = "n.criado_em DESC",
    antigo   = "n.criado_em ASC",
    views    = "n.views DESC",
    titulo   = "n.titulo ASC",
  }
  local ordem = ordem_map[f.ordem or "recente"] or "n.criado_em DESC"
 
  -- Sempre traz autor junto
  local sql = string.format([[
    SELECT n.*, a.nome as autor_nome, a.avatar_url as autor_avatar
    FROM noticias n
    LEFT JOIN autores a ON a.id = n.autor_id
    %s
    ORDER BY n.destaque DESC, %s
  ]], where_sql, ordem)
 
  return query(sql)
end

-- Score de trending: pondera views recentes + comentários recentes + destaque
-- Janela configurável em horas (padrão: 24h)
function M.get_trending(limite, horas)
  limite = tonumber(limite) or 10
  horas  = tonumber(horas)  or 24
 
  -- Views nas últimas N horas (via views_diarias do dia de hoje e ontem)
  -- + comentários recentes + boost de destaque
  return query(string.format([[
    SELECT
      n.*,
      a.nome  AS autor_nome,
      a.avatar_url AS autor_avatar,
      COALESCE(vd.views_recentes, 0)   AS views_recentes,
      COALESCE(cr.coments_recentes, 0) AS coments_recentes,
      (
        COALESCE(vd.views_recentes, 0) * 1.0
        + COALESCE(cr.coments_recentes, 0) * 3.0
        + (n.destaque * 10.0)
      ) AS score
    FROM noticias n
    LEFT JOIN autores a ON a.id = n.autor_id
    -- Views nas últimas N horas (agrega os dias relevantes)
    LEFT JOIN (
      SELECT noticia_id, SUM(total) AS views_recentes
      FROM views_diarias
      WHERE data >= date('now', '-%d hours')
      GROUP BY noticia_id
    ) vd ON vd.noticia_id = n.id
    -- Comentários aprovados nas últimas N horas
    LEFT JOIN (
      SELECT noticia_id, COUNT(*) AS coments_recentes
      FROM comentarios
      WHERE aprovado = 1
        AND criado_em >= datetime('now', '-%d hours')
      GROUP BY noticia_id
    ) cr ON cr.noticia_id = n.id
    -- Só notícias já publicadas
    WHERE (n.publicar_em = '' OR n.publicar_em <= datetime('now'))
    ORDER BY score DESC, n.criado_em DESC
    LIMIT %d
  ]], horas, horas, limite))
end
 
-- Score simples para widget inline (home/sidebar) — sem JOIN pesado
function M.get_trending_rapido(limite)
  limite = tonumber(limite) or 5
  return query(string.format([[
    SELECT n.id, n.titulo, n.jogo, n.categoria, n.views, n.destaque,
      n.criado_em,
      COALESCE(vd.hoje, 0) AS views_hoje
    FROM noticias n
    LEFT JOIN (
      SELECT noticia_id, total AS hoje
      FROM views_diarias WHERE data = date('now')
    ) vd ON vd.noticia_id = n.id
    WHERE (n.publicar_em = '' OR n.publicar_em <= datetime('now'))
    ORDER BY (COALESCE(vd.hoje,0) + n.destaque*5) DESC, n.criado_em DESC
    LIMIT %d
  ]], limite))
end
 
-- ─── Newsletter ───────────────────────────────────────────────────────────────
 
-- Gera token simples baseado em timestamp + email
local function gerar_token(email)
  return string.format("%x%x", math.floor(os.time()), #email * 7919)
end
 
-- Cadastra e-mail; retorna "ok", "ja_existe" ou "erro"
function M.cadastrar_newsletter(email)
  if not email or email:match("^%s*$") then return "erro" end
  -- Validação básica de formato
  if not email:match("^[^@]+@[^@]+%.[^@]+$") then return "erro" end
 
  local conn  = M.connect()
  local token = gerar_token(email)
 
  -- Verifica se já existe
  local exist = query(string.format(
    "SELECT id, ativo FROM newsletter WHERE email = %s LIMIT 1", escape(email)
  ))
  if #exist > 0 then
    if exist[1].ativo == 1 then return "ja_existe" end
    -- Reativa cadastro cancelado
    conn:exec(string.format(
      "UPDATE newsletter SET ativo=1, token=%s WHERE email=%s",
      escape(token), escape(email)
    ))
    return "reativado"
  end
 
  conn:exec(string.format(
    "INSERT INTO newsletter (email, token) VALUES (%s, %s)",
    escape(email), escape(token)
  ))
  return "ok"
end
 
-- Cancela inscrição pelo token
function M.cancelar_newsletter(token)
  if not token or token == "" then return false end
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE newsletter SET ativo=0 WHERE token=%s", escape(token)
  ))
  local rows = query(string.format(
    "SELECT id FROM newsletter WHERE token=%s AND ativo=0 LIMIT 1", escape(token)
  ))
  return #rows > 0
end
 
-- Lista todos os inscritos ativos (para o admin)
function M.get_newsletter_inscritos()
  return query("SELECT * FROM newsletter WHERE ativo=1 ORDER BY criado_em DESC")
end
 
function M.count_newsletter()
  local r = query("SELECT COUNT(*) AS n FROM newsletter WHERE ativo=1")
  return r[1] and r[1].n or 0
end
 
-- Remove permanentemente (admin)
function M.deletar_inscrito(id)
  local conn = M.connect()
  conn:exec("DELETE FROM newsletter WHERE id = " .. tonumber(id))
end
 
-- ─── Moderação de comentários ─────────────────────────────────────────────────
 
-- Retorna comentários pendentes (aprovado=0)
function M.get_comentarios_pendentes()
  return query([[
    SELECT c.*, n.titulo AS noticia_titulo
    FROM comentarios c
    JOIN noticias n ON n.id = c.noticia_id
    WHERE c.aprovado = 0
    ORDER BY c.criado_em DESC
  ]])
end
 
-- Aprova um comentário
function M.aprovar_comentario(id)
  local conn = M.connect()
  conn:exec("UPDATE comentarios SET aprovado=1 WHERE id=" .. tonumber(id))
end
 
-- Reprova (deleta) — reusa deletar_comentario existente
-- (já existe: M.deletar_comentario)
 
-- Retorna comentários aprovados de uma notícia
-- SUBSTITUI get_comentarios para filtrar aprovados
function M.get_comentarios_aprovados(noticia_id)
  return query(string.format(
    "SELECT * FROM comentarios WHERE noticia_id=%d AND aprovado=1 ORDER BY criado_em ASC",
    tonumber(noticia_id)
  ))
end
 
-- Contagem de pendentes (para badge no admin)
function M.count_comentarios_pendentes()
  local r = query("SELECT COUNT(*) AS n FROM comentarios WHERE aprovado=0")
  return r[1] and r[1].n or 0
end
 
-- get_comentarios_paginado: versão que suporta filtro de aprovação
function M.get_comentarios_paginado_v2(pagina, por_pagina, apenas_pendentes)
  pagina     = tonumber(pagina)     or 1
  por_pagina = tonumber(por_pagina) or 10
  local where = apenas_pendentes and "WHERE c.aprovado=0" or ""
  local total = query(string.format(
    "SELECT COUNT(*) AS total FROM comentarios c %s", where
  ))[1].total
  local offset = (pagina - 1) * por_pagina
  local rows = query(string.format([[
    SELECT c.*, n.titulo AS noticia_titulo
    FROM comentarios c
    JOIN noticias n ON n.id = c.noticia_id
    %s
    ORDER BY c.criado_em DESC
    LIMIT %d OFFSET %d
  ]], where, por_pagina, offset))
  return {
    rows          = rows,
    total         = total,
    pagina        = pagina,
    por_pagina    = por_pagina,
    total_paginas = math.ceil(total / por_pagina),
  }
end
 
-- ─── Agendamento de publicação ────────────────────────────────────────────────
 
-- Notícias agendadas ainda não publicadas
function M.get_agendadas()
  return query([[
    SELECT * FROM noticias
    WHERE publicar_em != '' AND publicar_em > datetime('now')
    ORDER BY publicar_em ASC
  ]])
end
 
-- Publica notícias cujo prazo já chegou (chame periodicamente no app)
function M.publicar_agendadas()
  local conn = M.connect()
  -- Marca como publicadas limpando o campo publicar_em
  conn:exec([[
    UPDATE noticias
    SET publicar_em = ''
    WHERE publicar_em != '' AND publicar_em <= datetime('now')
  ]])
  return conn:changes()  -- retorna quantas foram publicadas
end
 
-- Retorna notícias visíveis publicamente (já publicadas ou sem agendamento)
function M.get_noticias_publicadas()
  return query([[
    SELECT * FROM noticias
    WHERE publicar_em = '' OR publicar_em <= datetime('now')
    ORDER BY destaque DESC, criado_em DESC
  ]])
end
 
-- Discord Webhook: envia notificação quando uma notícia é publicada
-- url_webhook: string da URL do webhook do Discord
-- noticia: tabela com id, titulo, categoria, jogo
function M.notificar_discord(url_webhook, noticia)
  if not url_webhook or url_webhook == "" then return false end
 
  local jogo_txt = (noticia.jogo and noticia.jogo ~= "")
    and (" | 🎮 " .. noticia.jogo) or ""
 
  local payload = string.format(
    '{"embeds":[{"title":%s,"description":%s,"color":6579953,"fields":[{"name":"Categoria","value":%s,"inline":true}%s],"url":%s}]}',
    string.format("%q", noticia.titulo),
    string.format("%q", (noticia.conteudo or ""):sub(1, 200) .. "..."),
    string.format("%q", noticia.categoria or "Geral"),
    jogo_txt ~= "" and string.format(',{"name":"Jogo","value":%s,"inline":true}',
      string.format("%q", noticia.jogo)) or "",
    string.format("%q", "http://localhost:8080/noticias/" .. noticia.id)
  )
 
  -- Usa curl via os.execute (OpenResty tem restrições no socket HTTP nativo)
  local cmd = string.format(
    "curl -s -X POST -H 'Content-Type: application/json' -d %s %s &",
    string.format("%q", payload),
    string.format("%q", url_webhook)
  )
  os.execute(cmd)
  return true
end

return M