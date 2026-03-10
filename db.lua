-- Módulo central de acesso ao banco de dados SQLite
-- Usa lapis.db (baseado em sqlite3 via luasql ou lapis built-in)

local sqlite3 = require("lsqlite3")

local DB_PATH = "portal_gamer.db"
local db_conn = nil

local M = {}

-- Abre (ou cria) o banco e garante que as tabelas existem
function M.connect()
  if db_conn then return db_conn end

  db_conn = sqlite3.open(DB_PATH)

  -- Tabela de notícias
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS noticias (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo    TEXT    NOT NULL,
      conteudo  TEXT    NOT NULL,
      jogo      TEXT    NOT NULL DEFAULT '',
      criado_em TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  ]])

  -- Tabela de jogos (ranking)
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

-- Fecha a conexão (chamar no shutdown se necessário)
function M.close()
  if db_conn then
    db_conn:close()
    db_conn = nil
  end
end

-- ─── Helpers internos ────────────────────────────────────────────────────────

-- Executa uma query e retorna lista de rows como tabelas Lua
local function query(sql)
  local conn = M.connect()
  local rows = {}
  for row in conn:nrows(sql) do
    table.insert(rows, row)
  end
  return rows
end

-- Executa uma query com parâmetros (prepared statement simples via escape)
local function escape(val)
  if val == nil then return "NULL" end
  if type(val) == "number" then return tostring(val) end
  -- Escapa aspas simples duplicando-as (padrão SQL)
  return "'" .. tostring(val):gsub("'", "''") .. "'"
end

-- ─── Notícias ────────────────────────────────────────────────────────────────

-- Retorna todas as notícias, da mais recente para a mais antiga
function M.get_noticias()
  return query("SELECT * FROM noticias ORDER BY criado_em DESC")
end

-- Retorna uma notícia pelo ID
function M.get_noticia(id)
  local rows = query("SELECT * FROM noticias WHERE id = " .. tonumber(id))
  return rows[1]
end

-- Insere uma nova notícia
function M.criar_noticia(titulo, conteudo, jogo)
  local conn = M.connect()
  local sql = string.format(
    "INSERT INTO noticias (titulo, conteudo, jogo) VALUES (%s, %s, %s)",
    escape(titulo), escape(conteudo), escape(jogo or "")
  )
  conn:exec(sql)
  return conn:last_insert_rowid()
end

-- Remove uma notícia pelo ID
function M.deletar_noticia(id)
  local conn = M.connect()
  conn:exec("DELETE FROM noticias WHERE id = " .. tonumber(id))
end

-- ─── Jogos / Ranking ─────────────────────────────────────────────────────────

-- Retorna todos os jogos ordenados pela posição no ranking
function M.get_jogos()
  return query("SELECT * FROM jogos ORDER BY posicao ASC")
end

-- Retorna um jogo pelo ID
function M.get_jogo(id)
  local rows = query("SELECT * FROM jogos WHERE id = " .. tonumber(id))
  return rows[1]
end

-- Insere um novo jogo no ranking
function M.criar_jogo(nome, genero, players, posicao)
  local conn = M.connect()
  local sql = string.format(
    "INSERT INTO jogos (nome, genero, players, posicao) VALUES (%s, %s, %s, %s)",
    escape(nome), escape(genero or ""), escape(players), escape(tonumber(posicao) or 0)
  )
  conn:exec(sql)
  return conn:last_insert_rowid()
end

-- Atualiza a posição de um jogo
function M.atualizar_posicao(id, nova_posicao)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE jogos SET posicao = %d WHERE id = %d",
    tonumber(nova_posicao), tonumber(id)
  ))
end

-- Remove um jogo pelo ID
function M.deletar_jogo(id)
  local conn = M.connect()
  conn:exec("DELETE FROM jogos WHERE id = " .. tonumber(id))
end

return M