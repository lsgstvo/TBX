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


  -- Migrações seguras para bancos já existentes
  db_conn:exec("ALTER TABLE noticias ADD COLUMN categoria  TEXT    NOT NULL DEFAULT 'Geral'")
  db_conn:exec("ALTER TABLE noticias ADD COLUMN destaque   INTEGER NOT NULL DEFAULT 0")
  db_conn:exec("ALTER TABLE noticias ADD COLUMN views      INTEGER NOT NULL DEFAULT 0")
  db_conn:exec("ALTER TABLE jogos    ADD COLUMN descricao  TEXT    NOT NULL DEFAULT ''")
  db_conn:exec("ALTER TABLE jogos    ADD COLUMN imagem_url TEXT    NOT NULL DEFAULT ''")

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

return M