-- db.lua
local sqlite3 = require("lsqlite3")

local DB_PATH = "portal_gamer.db"
local db_conn = nil
local M = {}

function M.connect()
  if db_conn then return db_conn end
  db_conn = sqlite3.open(DB_PATH)

  -- Notícias: adicionados campos categoria e destaque
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS noticias (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo    TEXT    NOT NULL,
      conteudo  TEXT    NOT NULL,
      jogo      TEXT    NOT NULL DEFAULT '',
      categoria TEXT    NOT NULL DEFAULT 'Geral',
      destaque  INTEGER NOT NULL DEFAULT 0,
      criado_em TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  ]])

  -- Jogos: adicionados campos descricao e imagem_url
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

  -- Categorias disponíveis (tabela de referência)
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS categorias (
      id   INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT    NOT NULL UNIQUE
    );
  ]])

  -- Migração segura: adiciona colunas novas se ainda não existirem
  -- (necessário para bancos já existentes)
  db_conn:exec("ALTER TABLE noticias ADD COLUMN categoria TEXT NOT NULL DEFAULT 'Geral'")
  db_conn:exec("ALTER TABLE noticias ADD COLUMN destaque  INTEGER NOT NULL DEFAULT 0")
  db_conn:exec("ALTER TABLE jogos    ADD COLUMN descricao  TEXT NOT NULL DEFAULT ''")
  db_conn:exec("ALTER TABLE jogos    ADD COLUMN imagem_url TEXT NOT NULL DEFAULT ''")

  -- Categorias padrão
  local cats = { "Geral", "Update", "Lançamento", "E-Sports", "Hardware", "Indie" }
  for _, c in ipairs(cats) do
    db_conn:exec(string.format(
      "INSERT OR IGNORE INTO categorias (nome) VALUES ('%s')", c
    ))
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

-- Notícias filtradas por categoria
function M.get_noticias_por_categoria(categoria)
  return query(string.format(
    "SELECT * FROM noticias WHERE categoria = %s ORDER BY criado_em DESC",
    escape(categoria)
  ))
end

-- ─── Notícias ────────────────────────────────────────────────────────────────

function M.get_noticias()
  return query("SELECT * FROM noticias ORDER BY destaque DESC, criado_em DESC")
end

-- Somente as notícias em destaque
function M.get_destaques()
  return query("SELECT * FROM noticias WHERE destaque = 1 ORDER BY criado_em DESC")
end

-- Paginação com filtro opcional de categoria
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
    rows          = rows,
    total         = total,
    pagina        = pagina,
    por_pagina    = por_pagina,
    total_paginas = math.ceil(total / por_pagina),
    categoria     = categoria or "",
  }
end

-- Busca por termo no título, jogo ou categoria
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

function M.criar_noticia(titulo, conteudo, jogo, categoria, destaque)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO noticias (titulo, conteudo, jogo, categoria, destaque) VALUES (%s, %s, %s, %s, %d)",
    escape(titulo), escape(conteudo), escape(jogo or ""),
    escape(categoria or "Geral"), destaque and 1 or 0
  ))
  return conn:last_insert_rowid()
end

function M.editar_noticia(id, titulo, conteudo, jogo, categoria, destaque)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE noticias SET titulo=%s, conteudo=%s, jogo=%s, categoria=%s, destaque=%d WHERE id=%d",
    escape(titulo), escape(conteudo), escape(jogo or ""),
    escape(categoria or "Geral"), destaque and 1 or 0, tonumber(id)
  ))
end

function M.deletar_noticia(id)
  local conn = M.connect()
  conn:exec("DELETE FROM noticias WHERE id = " .. tonumber(id))
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
    "INSERT INTO jogos (nome, genero, players, posicao, descricao, imagem_url) VALUES (%s,%s,%s,%s,%s,%s)",
    escape(nome), escape(genero or ""), escape(players),
    escape(tonumber(posicao) or 0),
    escape(descricao or ""), escape(imagem_url or "")
  ))
  return conn:last_insert_rowid()
end

function M.editar_jogo(id, nome, genero, players, posicao, descricao, imagem_url)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE jogos SET nome=%s, genero=%s, players=%s, posicao=%s, descricao=%s, imagem_url=%s WHERE id=%d",
    escape(nome), escape(genero or ""), escape(players),
    escape(tonumber(posicao) or 0),
    escape(descricao or ""), escape(imagem_url or ""),
    tonumber(id)
  ))
end

function M.deletar_jogo(id)
  local conn = M.connect()
  conn:exec("DELETE FROM jogos WHERE id = " .. tonumber(id))
end

return M