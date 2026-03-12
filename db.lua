-- db.lua
-- Módulo central de acesso ao banco de dados SQLite

local sqlite3 = require("lsqlite3")

local DB_PATH = "portal_gamer.db"
local db_conn = nil

local M = {}

function M.connect()
  if db_conn then return db_conn end
  db_conn = sqlite3.open(DB_PATH)
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS noticias (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo    TEXT    NOT NULL,
      conteudo  TEXT    NOT NULL,
      jogo      TEXT    NOT NULL DEFAULT '',
      criado_em TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  ]])
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS jogos (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      nome      TEXT    NOT NULL,
      genero    TEXT    NOT NULL DEFAULT '',
      players   TEXT    NOT NULL,
      posicao   INTEGER NOT NULL DEFAULT 0
    );
  ]])
  return db_conn
end

function M.close()
  if db_conn then
    db_conn:close()
    db_conn = nil
  end
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function query(sql)
  local conn = M.connect()
  local rows = {}
  for row in conn:nrows(sql) do
    table.insert(rows, row)
  end
  return rows
end

local function escape(val)
  if val == nil then return "NULL" end
  if type(val) == "number" then return tostring(val) end
  return "'" .. tostring(val):gsub("'", "''") .. "'"
end

-- ─── Notícias ────────────────────────────────────────────────────────────────

-- Retorna todas as notícias sem paginação (usado na home e API)
function M.get_noticias()
  return query("SELECT * FROM noticias ORDER BY criado_em DESC")
end

-- Retorna notícias paginadas
-- Retorna tabela: { rows, total, paginas, pagina_atual }
function M.get_noticias_paginadas(pagina, por_pagina)
  pagina     = tonumber(pagina)     or 1
  por_pagina = tonumber(por_pagina) or 6

  local offset     = (pagina - 1) * por_pagina
  local total_rows = query("SELECT COUNT(*) as total FROM noticias")
  local total      = total_rows[1] and total_rows[1].total or 0
  local paginas    = math.max(1, math.ceil(total / por_pagina))

  local rows = query(string.format(
    "SELECT * FROM noticias ORDER BY criado_em DESC LIMIT %d OFFSET %d",
    por_pagina, offset
  ))

  return { rows = rows, total = total, paginas = paginas, pagina_atual = pagina }
end

-- Busca notícias por termo no título ou nome do jogo
function M.buscar_noticias(termo)
  local t = escape("%" .. (termo or "") .. "%")
  return query(string.format(
    "SELECT * FROM noticias WHERE titulo LIKE %s OR jogo LIKE %s ORDER BY criado_em DESC",
    t, t
  ))
end

-- Retorna notícias de um jogo específico
function M.get_noticias_por_jogo(nome_jogo)
  return query(string.format(
    "SELECT * FROM noticias WHERE jogo = %s ORDER BY criado_em DESC",
    escape(nome_jogo)
  ))
end

-- Retorna uma notícia pelo ID
function M.get_noticia(id)
  local rows = query("SELECT * FROM noticias WHERE id = " .. tonumber(id))
  return rows[1]
end

-- Insere uma nova notícia
function M.criar_noticia(titulo, conteudo, jogo)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO noticias (titulo, conteudo, jogo) VALUES (%s, %s, %s)",
    escape(titulo), escape(conteudo), escape(jogo or "")
  ))
  return conn:last_insert_rowid()
end

-- Atualiza uma notícia existente
function M.editar_noticia(id, titulo, conteudo, jogo)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE noticias SET titulo = %s, conteudo = %s, jogo = %s WHERE id = %d",
    escape(titulo), escape(conteudo), escape(jogo or ""), tonumber(id)
  ))
end

-- Remove uma notícia pelo ID
function M.deletar_noticia(id)
  local conn = M.connect()
  conn:exec("DELETE FROM noticias WHERE id = " .. tonumber(id))
end

-- ─── Jogos / Ranking ─────────────────────────────────────────────────────────

function M.get_jogos()
  return query("SELECT * FROM jogos ORDER BY posicao ASC")
end

function M.get_jogo(id)
  local rows = query("SELECT * FROM jogos WHERE id = " .. tonumber(id))
  return rows[1]
end

-- Busca jogo pelo nome exato
function M.get_jogo_por_nome(nome)
  local rows = query(string.format(
    "SELECT * FROM jogos WHERE nome = %s LIMIT 1", escape(nome)
  ))
  return rows[1]
end

function M.criar_jogo(nome, genero, players, posicao)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO jogos (nome, genero, players, posicao) VALUES (%s, %s, %s, %s)",
    escape(nome), escape(genero or ""), escape(players), escape(tonumber(posicao) or 0)
  ))
  return conn:last_insert_rowid()
end

function M.atualizar_posicao(id, nova_posicao)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE jogos SET posicao = %d WHERE id = %d",
    tonumber(nova_posicao), tonumber(id)
  ))
end

function M.deletar_jogo(id)
  local conn = M.connect()
  conn:exec("DELETE FROM jogos WHERE id = " .. tonumber(id))
end

return M