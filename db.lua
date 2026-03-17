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

-- Curtidas/descurtidas por IP por notícia
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS curtidas (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      noticia_id INTEGER NOT NULL,
      tipo       TEXT    NOT NULL CHECK(tipo IN ('like','dislike')),
      ip         TEXT    NOT NULL DEFAULT '',
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now')),
      UNIQUE(noticia_id, ip),
      FOREIGN KEY (noticia_id) REFERENCES noticias(id) ON DELETE CASCADE
    );
  ]])
 
  -- Log de atividades do admin
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS log_atividades (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      acao      TEXT NOT NULL,
      entidade  TEXT NOT NULL DEFAULT '',
      detalhe   TEXT NOT NULL DEFAULT '',
      ip        TEXT NOT NULL DEFAULT '',
      criado_em TEXT NOT NULL DEFAULT (datetime('now'))
    );
  ]])
 
  -- Migrações seguras nas notícias
  db_conn:exec("ALTER TABLE noticias ADD COLUMN likes    INTEGER NOT NULL DEFAULT 0")
  db_conn:exec("ALTER TABLE noticias ADD COLUMN dislikes INTEGER NOT NULL DEFAULT 0")

  -- Conquistas desbloqueadas por leitor (identificado por cookie/IP)
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS conquistas (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      leitor_id  TEXT    NOT NULL,
      tipo       TEXT    NOT NULL,
      desbloqueada_em TEXT NOT NULL DEFAULT (datetime('now')),
      UNIQUE(leitor_id, tipo)
    );
  ]])
 
  -- Próximos lançamentos de jogos
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS lancamentos (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      nome        TEXT    NOT NULL,
      plataformas TEXT    NOT NULL DEFAULT '',
      data_lancamento TEXT NOT NULL DEFAULT '',
      genero      TEXT    NOT NULL DEFAULT '',
      descricao   TEXT    NOT NULL DEFAULT '',
      imagem_url  TEXT    NOT NULL DEFAULT '',
      site_url    TEXT    NOT NULL DEFAULT '',
      criado_em   TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  ]])

  -- Categorias padrão
  for _, c in ipairs({ "Geral", "Update", "Lançamento", "E-Sports", "Hardware", "Indie" }) do
    db_conn:exec(string.format("INSERT OR IGNORE INTO categorias (nome) VALUES ('%s')", c))
  end

-- Histórico de leituras por leitor
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS historico_leituras (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      leitor_id  TEXT    NOT NULL,
      noticia_id INTEGER NOT NULL,
      lido_em    TEXT    NOT NULL DEFAULT (datetime('now')),
      UNIQUE(leitor_id, noticia_id),
      FOREIGN KEY (noticia_id) REFERENCES noticias(id) ON DELETE CASCADE
    );
  ]])
 
  -- Enquetes
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS enquetes (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      noticia_id INTEGER,
      pergunta   TEXT    NOT NULL,
      ativa      INTEGER NOT NULL DEFAULT 1,
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (noticia_id) REFERENCES noticias(id) ON DELETE SET NULL
    );
  ]])
 
  -- Opções das enquetes
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS enquete_opcoes (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      enquete_id INTEGER NOT NULL,
      texto      TEXT    NOT NULL,
      votos      INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (enquete_id) REFERENCES enquetes(id) ON DELETE CASCADE
    );
  ]])
 
  -- Votos de enquete por IP (evita duplicatas)
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS enquete_votos (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      enquete_id INTEGER NOT NULL,
      opcao_id   INTEGER NOT NULL,
      ip         TEXT    NOT NULL DEFAULT '',
      votado_em  TEXT    NOT NULL DEFAULT (datetime('now')),
      UNIQUE(enquete_id, ip),
      FOREIGN KEY (enquete_id) REFERENCES enquetes(id) ON DELETE CASCADE
    );
  ]])
 
  -- Log de performance (tempo de resposta por rota)
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS perf_log (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      rota       TEXT    NOT NULL,
      metodo     TEXT    NOT NULL DEFAULT 'GET',
      status     INTEGER NOT NULL DEFAULT 200,
      ms         INTEGER NOT NULL DEFAULT 0,
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  ]])

  -- Configurações persistentes do leitor (avatar, etc)
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS leitores (
      leitor_id TEXT PRIMARY KEY,
      avatar    TEXT NOT NULL DEFAULT '👤',
      criado_em TEXT NOT NULL DEFAULT (datetime('now'))
    );
  ]])


  -- Notas rápidas pessoais do leitor por notícia
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS notas_rapidas (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      leitor_id     TEXT    NOT NULL,
      noticia_id    INTEGER NOT NULL,
      texto         TEXT    NOT NULL DEFAULT '',
      criado_em     TEXT    NOT NULL DEFAULT (datetime('now')),
      atualizado_em TEXT    NOT NULL DEFAULT (datetime('now')),
      UNIQUE(leitor_id, noticia_id),
      FOREIGN KEY (noticia_id) REFERENCES noticias(id) ON DELETE CASCADE
    );
  ]])

  -- Crônicas/Editoriais
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS cronicas (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo      TEXT    NOT NULL,
      subtitulo   TEXT    NOT NULL DEFAULT '',
      conteudo    TEXT    NOT NULL,
      autor_id    INTEGER,
      imagem_url  TEXT    NOT NULL DEFAULT '',
      tags_str    TEXT    NOT NULL DEFAULT '',
      destaque    INTEGER NOT NULL DEFAULT 0,
      publicar_em TEXT    NOT NULL DEFAULT '',
      views       INTEGER NOT NULL DEFAULT 0,
      criado_em   TEXT    NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (autor_id) REFERENCES autores(id) ON DELETE SET NULL
    );
  ]])


  -- Galeria de imagens dos jogos
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS galeria (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      jogo_id    INTEGER NOT NULL,
      url        TEXT    NOT NULL,
      legenda    TEXT    NOT NULL DEFAULT '',
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (jogo_id) REFERENCES jogos(id) ON DELETE CASCADE
    );
  ]])

  -- Favoritos/bookmarks do leitor
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS favoritos (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      leitor_id  TEXT    NOT NULL,
      noticia_id INTEGER NOT NULL,
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now')),
      UNIQUE(leitor_id, noticia_id),
      FOREIGN KEY (noticia_id) REFERENCES noticias(id) ON DELETE CASCADE
    );
  ]])

  -- Glossário gamer
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS glossario (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      termo      TEXT    NOT NULL UNIQUE,
      definicao  TEXT    NOT NULL,
      categoria  TEXT    NOT NULL DEFAULT 'Geral',
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now'))
    );
  ]])

  -- A/B test de títulos de notícias
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS ab_testes (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      noticia_id INTEGER NOT NULL,
      titulo_b   TEXT    NOT NULL,
      views_a    INTEGER NOT NULL DEFAULT 0,
      views_b    INTEGER NOT NULL DEFAULT 0,
      ativo      INTEGER NOT NULL DEFAULT 1,
      criado_em  TEXT    NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (noticia_id) REFERENCES noticias(id) ON DELETE CASCADE
    );
  ]])

  -- Citações de games
  db_conn:exec([[
    CREATE TABLE IF NOT EXISTS citacoes (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      texto     TEXT NOT NULL,
      personagem TEXT NOT NULL DEFAULT '',
      jogo      TEXT NOT NULL DEFAULT '',
      criado_em TEXT NOT NULL DEFAULT (datetime('now'))
    );
  ]])

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
  for _, n in ipairs(rows) do
    local palavras = 0
    for _ in (n.conteudo or ""):gmatch("%S+") do palavras = palavras + 1 end
    n.tempo_leitura = math.max(1, math.ceil(palavras / 200))
  end
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

-- Retorna contagens e voto do IP atual
function M.get_curtidas(noticia_id, ip)
  noticia_id = tonumber(noticia_id)
  local contagem = query(string.format([[
    SELECT
      SUM(tipo='like')    AS likes,
      SUM(tipo='dislike') AS dislikes
    FROM curtidas WHERE noticia_id = %d
  ]], noticia_id))[1] or { likes = 0, dislikes = 0 }
 
  local meu_voto = nil
  if ip and ip ~= "" then
    local rows = query(string.format(
      "SELECT tipo FROM curtidas WHERE noticia_id=%d AND ip=%s LIMIT 1",
      noticia_id, escape(ip)
    ))
    meu_voto = rows[1] and rows[1].tipo or nil
  end
 
  return {
    likes    = tonumber(contagem.likes)    or 0,
    dislikes = tonumber(contagem.dislikes) or 0,
    meu_voto = meu_voto,
  }
end
 
-- Registra ou alterna curtida
-- Retorna o estado atualizado { likes, dislikes, meu_voto }
function M.curtir(noticia_id, tipo, ip)
  noticia_id = tonumber(noticia_id)
  if tipo ~= "like" and tipo ~= "dislike" then return nil end
  local conn = M.connect()
 
  -- Verifica voto existente
  local existente = query(string.format(
    "SELECT id, tipo FROM curtidas WHERE noticia_id=%d AND ip=%s LIMIT 1",
    noticia_id, escape(ip)
  ))
 
  if #existente > 0 then
    if existente[1].tipo == tipo then
      -- Mesmo voto: remove (toggle off)
      conn:exec("DELETE FROM curtidas WHERE id=" .. existente[1].id)
    else
      -- Voto diferente: troca
      conn:exec(string.format(
        "UPDATE curtidas SET tipo=%s WHERE id=%d",
        escape(tipo), existente[1].id
      ))
    end
  else
    -- Novo voto
    conn:exec(string.format(
      "INSERT INTO curtidas (noticia_id, tipo, ip) VALUES (%d, %s, %s)",
      noticia_id, escape(tipo), escape(ip)
    ))
  end
 
  -- Sincroniza contadores na tabela noticias (cache denormalizado)
  local c = M.get_curtidas(noticia_id, ip)
  conn:exec(string.format(
    "UPDATE noticias SET likes=%d, dislikes=%d WHERE id=%d",
    c.likes, c.dislikes, noticia_id
  ))
 
  return c
end
 
-- Top notícias mais curtidas
function M.get_mais_curtidas(limite)
  return query(string.format([[
    SELECT id, titulo, likes, dislikes, categoria, jogo, criado_em
    FROM noticias
    WHERE likes > 0
    ORDER BY likes DESC, criado_em DESC
    LIMIT %d
  ]], tonumber(limite) or 10))
end
 
-- ─── Log de atividades ────────────────────────────────────────────────────────
 
-- Registra uma ação no log
function M.log(acao, entidade, detalhe, ip)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO log_atividades (acao, entidade, detalhe, ip) VALUES (%s,%s,%s,%s)",
    escape(acao), escape(entidade or ""), escape(detalhe or ""), escape(ip or "")
  ))
end
 
-- Retorna log paginado
function M.get_log(pagina, por_pagina)
  pagina     = tonumber(pagina)     or 1
  por_pagina = tonumber(por_pagina) or 20
  local total  = query("SELECT COUNT(*) AS n FROM log_atividades")[1].n
  local offset = (pagina - 1) * por_pagina
  local rows   = query(string.format([[
    SELECT * FROM log_atividades
    ORDER BY criado_em DESC
    LIMIT %d OFFSET %d
  ]], por_pagina, offset))
  return {
    rows          = rows,
    total         = total,
    pagina        = pagina,
    total_paginas = math.ceil(total / por_pagina),
  }
end
 
-- Limpa logs antigos (mantém últimos N dias)
function M.limpar_log_antigo(dias)
  local conn = M.connect()
  conn:exec(string.format(
    "DELETE FROM log_atividades WHERE criado_em < datetime('now','-%d days')",
    tonumber(dias) or 90
  ))
end
 
-- ─── Timeline do portal (para /about) ────────────────────────────────────────
 
-- Retorna dados consolidados para a página About/Timeline
function M.get_dados_about()
  -- Primeira notícia (nascimento do portal)
  local primeira = query(
    "SELECT criado_em FROM noticias ORDER BY criado_em ASC LIMIT 1"
  )[1]
 
  -- Marcos mensais: meses com mais publicações
  local por_mes = query([[
    SELECT strftime('%Y-%m', criado_em) AS mes, COUNT(*) AS total
    FROM noticias
    GROUP BY mes ORDER BY total DESC LIMIT 3
  ]])
 
  -- Jogos mais cobertos
  local top_jogos = query([[
    SELECT jogo, COUNT(*) AS total FROM noticias
    WHERE jogo != ''
    GROUP BY jogo ORDER BY total DESC LIMIT 5
  ]])
 
  -- Autores mais ativos
  local top_autores = query([[
    SELECT a.nome, a.avatar_url, COUNT(n.id) AS total
    FROM autores a
    LEFT JOIN noticias n ON n.autor_id = a.id
    GROUP BY a.id ORDER BY total DESC LIMIT 3
  ]])
 
  -- Totais gerais
  local totais = {
    noticias  = query("SELECT COUNT(*) AS n FROM noticias")[1].n,
    jogos     = query("SELECT COUNT(*) AS n FROM jogos")[1].n,
    autores   = query("SELECT COUNT(*) AS n FROM autores")[1].n,
    comentarios = query("SELECT COUNT(*) AS n FROM comentarios WHERE aprovado=1")[1].n,
    curtidas  = query("SELECT SUM(likes) AS n FROM noticias")[1].n or 0,
    inscritos = query("SELECT COUNT(*) AS n FROM newsletter WHERE ativo=1")[1].n,
  }
 
  -- Notícia mais popular de todos os tempos
  local mais_popular = query(
    "SELECT id, titulo, views, likes FROM noticias ORDER BY views DESC LIMIT 1"
  )[1]
 
  return {
    primeira      = primeira,
    por_mes       = por_mes,
    top_jogos     = top_jogos,
    top_autores   = top_autores,
    totais        = totais,
    mais_popular  = mais_popular,
  }
end

-- Definição de todas as conquistas disponíveis
local CONQUISTAS_DEF = {
  { tipo = "primeira_visita",    nome = "Bem-vindo!",        desc = "Primeira visita ao portal",           ico = "👋", cor = "#6366f1" },
  { tipo = "leitor_5",           nome = "Curioso",           desc = "Leu 5 notícias",                      ico = "📰", cor = "#22c55e" },
  { tipo = "leitor_25",          nome = "Entusiasta",        desc = "Leu 25 notícias",                     ico = "🔥", cor = "#f59e0b" },
  { tipo = "leitor_100",         nome = "Viciado em News",   desc = "Leu 100 notícias",                    ico = "🏆", cor = "#f43f5e" },
  { tipo = "comentarista",       nome = "Voz da Comunidade", desc = "Fez seu primeiro comentário",         ico = "💬", cor = "#8b5cf6" },
  { tipo = "curtidor",           nome = "Like Master",       desc = "Curtiu 10 notícias",                  ico = "👍", cor = "#ec4899" },
  { tipo = "explorador",         nome = "Explorador",        desc = "Visitou 5 categorias diferentes",     ico = "🗺", cor = "#14b8a6" },
  { tipo = "fiel",               nome = "Leitor Fiel",       desc = "Voltou ao portal em 3 dias seguidos", ico = "📅", cor = "#f97316" },
  { tipo = "madrugador",         nome = "Madrugador",        desc = "Leu uma notícia antes das 6h",        ico = "🌙", cor = "#6366f1" },
  { tipo = "newsletter",         nome = "Conectado",         desc = "Inscrito na newsletter",              ico = "📧", cor = "#0ea5e9" },
}
 
-- Retorna definição de uma conquista pelo tipo
function M.get_conquista_def(tipo)
  for _, c in ipairs(CONQUISTAS_DEF) do
    if c.tipo == tipo then return c end
  end
  return nil
end
 
-- Retorna todas as definições (para a página de conquistas)
function M.get_conquistas_def()
  return CONQUISTAS_DEF
end
 
-- Conquistas já desbloqueadas por um leitor
function M.get_conquistas_leitor(leitor_id)
  if not leitor_id or leitor_id == "" then return {} end
  local rows = query(string.format(
    "SELECT tipo, desbloqueada_em FROM conquistas WHERE leitor_id = %s ORDER BY desbloqueada_em ASC",
    escape(leitor_id)
  ))
  -- Enriquece com a definição
  local resultado = {}
  for _, r in ipairs(rows) do
    local def = M.get_conquista_def(r.tipo)
    if def then
      local item = {}
      for k, v in pairs(def) do item[k] = v end
      item.desbloqueada_em = r.desbloqueada_em
      table.insert(resultado, item)
    end
  end
  return resultado
end
 
-- Tenta desbloquear uma conquista; retorna true se foi nova
function M.desbloquear(leitor_id, tipo)
  if not leitor_id or leitor_id == "" then return false end
  if not M.get_conquista_def(tipo) then return false end
  local conn = M.connect()
  -- INSERT OR IGNORE: não duplica
  conn:exec(string.format(
    "INSERT OR IGNORE INTO conquistas (leitor_id, tipo) VALUES (%s, %s)",
    escape(leitor_id), escape(tipo)
  ))
  return conn:changes() > 0
end
 
-- Verifica conquistas com base no comportamento atual do leitor
-- views_hoje: noticias vistas nesta sessão (número)
-- hora: hora atual (0-23)
-- ctx: tabela com flags { comentou, curtiu, newsletter, categorias_visitadas }
function M.verificar_conquistas(leitor_id, ctx)
  if not leitor_id or leitor_id == "" then return {} end
  ctx = ctx or {}
  local novas = {}
 
  -- Total de notícias lidas pelo leitor
  local total_lidas = query(string.format(
    "SELECT COUNT(*) AS n FROM conquistas WHERE leitor_id=%s AND tipo LIKE 'leitor_%%'",
    escape(leitor_id)
  ))[1].n
 
  -- Views totais registradas (via cookie no app)
  local views = tonumber(ctx.views_total) or 0
 
  local function tentar(tipo)
    if M.desbloquear(leitor_id, tipo) then
      local def = M.get_conquista_def(tipo)
      if def then table.insert(novas, def) end
    end
  end
 
  -- Primeira visita
  tentar("primeira_visita")
 
  -- Por número de views
  if views >= 5   then tentar("leitor_5")   end
  if views >= 25  then tentar("leitor_25")  end
  if views >= 100 then tentar("leitor_100") end
 
  -- Madrugador (hora entre 0 e 5)
  local hora = tonumber(ctx.hora) or os.date("*t").hour
  if hora >= 0 and hora < 6 then tentar("madrugador") end
 
  -- Ações específicas
  if ctx.comentou    then tentar("comentarista") end
  if ctx.newsletter  then tentar("newsletter")   end
 
  -- Curtidas acumuladas
  if tonumber(ctx.curtidas_total) and ctx.curtidas_total >= 10 then
    tentar("curtidor")
  end
 
  -- Categorias exploradas
  if tonumber(ctx.categorias_visitadas) and ctx.categorias_visitadas >= 5 then
    tentar("explorador")
  end
 
  return novas
end
 
-- Ranking de leitores com mais conquistas (para /mapa ou /stats)
function M.get_ranking_conquistas(limite)
  return query(string.format([[
    SELECT leitor_id, COUNT(*) AS total
    FROM conquistas
    GROUP BY leitor_id
    ORDER BY total DESC
    LIMIT %d
  ]], tonumber(limite) or 10))
end
 
-- ─── Análise SEO ──────────────────────────────────────────────────────────────
 
-- Calcula score SEO de uma notícia (0-100) e retorna sugestões
function M.analisar_seo(noticia)
  local score    = 0
  local checks   = {}   -- { ok, texto }
  local avisos   = {}
  local titulo   = noticia.titulo   or ""
  local conteudo = noticia.conteudo or ""
  local jogo     = noticia.jogo     or ""
  local tags_count = 0
 
  -- Obtém tags da notícia
  local tags = M.get_tags_da_noticia(noticia.id)
  tags_count = #tags
 
  -- 1. Comprimento do título (ideal: 40-60 chars)
  local t_len = #titulo
  if t_len >= 10 then
    score = score + 10
    table.insert(checks, { ok = true, texto = "Título presente (" .. t_len .. " chars)" })
  else
    table.insert(checks, { ok = false, texto = "Título muito curto (mín. 10 chars)" })
  end
  if t_len >= 40 and t_len <= 60 then
    score = score + 10
    table.insert(checks, { ok = true, texto = "Comprimento do título ideal (40-60 chars)" })
  elseif t_len > 60 then
    table.insert(checks, { ok = false, texto = "Título muito longo (" .. t_len .. " > 60 chars)" })
    table.insert(avisos, "Encurte o título para menos de 60 caracteres.")
  else
    table.insert(checks, { ok = false, texto = "Título curto demais para SEO (<40 chars)" })
  end
 
  -- 2. Conteúdo (ideal: >300 palavras)
  local palavras = 0
  for _ in conteudo:gmatch("%S+") do palavras = palavras + 1 end
  if palavras >= 100 then
    score = score + 10
    table.insert(checks, { ok = true, texto = "Conteúdo com texto suficiente (" .. palavras .. " palavras)" })
  else
    table.insert(checks, { ok = false, texto = "Pouco conteúdo (ideal: 100+ palavras, atual: " .. palavras .. ")" })
    table.insert(avisos, "Adicione mais texto para melhorar o ranqueamento.")
  end
  if palavras >= 300 then
    score = score + 10
    table.insert(checks, { ok = true, texto = "Conteúdo longo e rico (300+ palavras)" })
  end
 
  -- 3. Jogo relacionado (palavra-chave principal)
  if jogo ~= "" then
    score = score + 10
    table.insert(checks, { ok = true, texto = "Jogo relacionado definido: " .. jogo })
    -- Verifica se o nome do jogo aparece no título
    if titulo:lower():find(jogo:lower(), 1, true) then
      score = score + 10
      table.insert(checks, { ok = true, texto = "Palavra-chave (jogo) aparece no título" })
    else
      table.insert(checks, { ok = false, texto = "Palavra-chave (jogo) ausente no título" })
      table.insert(avisos, "Inclua o nome do jogo no título para melhor ranqueamento.")
    end
  else
    table.insert(checks, { ok = false, texto = "Nenhum jogo relacionado definido" })
    table.insert(avisos, "Defina um jogo relacionado para melhorar a relevância.")
  end
 
  -- 4. Tags
  if tags_count >= 3 then
    score = score + 10
    table.insert(checks, { ok = true, texto = "Tags suficientes (" .. tags_count .. " tags)" })
  elseif tags_count > 0 then
    score = score + 5
    table.insert(checks, { ok = false, texto = "Poucas tags (" .. tags_count .. ", ideal: 3+)" })
    table.insert(avisos, "Adicione pelo menos 3 tags para melhor categorização.")
  else
    table.insert(checks, { ok = false, texto = "Sem tags definidas" })
    table.insert(avisos, "Adicione tags relevantes à notícia.")
  end
 
  -- 5. Imagem de capa
  if noticia.imagem_url and noticia.imagem_url ~= "" then
    score = score + 10
    table.insert(checks, { ok = true, texto = "Imagem de capa presente (Open Graph)" })
  else
    table.insert(checks, { ok = false, texto = "Sem imagem de capa (prejudica Open Graph)" })
    table.insert(avisos, "Adicione uma imagem de capa para melhor compartilhamento em redes sociais.")
  end
 
  -- 6. Categoria
  if noticia.categoria and noticia.categoria ~= "Geral" then
    score = score + 10
    table.insert(checks, { ok = true, texto = "Categoria específica: " .. noticia.categoria })
  else
    table.insert(checks, { ok = false, texto = "Categoria genérica (Geral) — seja mais específico" })
  end
 
  -- 7. Destaque (engajamento)
  if noticia.destaque == 1 then
    score = score + 5
    table.insert(checks, { ok = true, texto = "Notícia em destaque (maior visibilidade)" })
  end
 
  -- Classificação por score
  local grade
  if     score >= 85 then grade = { letra = "A", cor = "#4ade80", label = "Excelente" }
  elseif score >= 70 then grade = { letra = "B", cor = "#a3e635", label = "Bom" }
  elseif score >= 50 then grade = { letra = "C", cor = "#f59e0b", label = "Regular" }
  elseif score >= 30 then grade = { letra = "D", cor = "#f97316", label = "Fraco" }
  else                    grade = { letra = "F", cor = "#f43f5e", label = "Crítico" }
  end
 
  return {
    score   = score,
    grade   = grade,
    checks  = checks,
    avisos  = avisos,
    palavras = palavras,
    tags    = tags_count,
  }
end
 
-- ─── Próximos lançamentos ─────────────────────────────────────────────────────
 
function M.get_lancamentos(apenas_futuros)
  if apenas_futuros then
    return query([[
      SELECT * FROM lancamentos
      WHERE data_lancamento >= date('now')
      ORDER BY data_lancamento ASC
    ]])
  end
  return query("SELECT * FROM lancamentos ORDER BY data_lancamento ASC")
end
 
function M.get_lancamento(id)
  local rows = query("SELECT * FROM lancamentos WHERE id=" .. tonumber(id))
  return rows[1]
end
 
function M.criar_lancamento(nome, plataformas, data_lancamento, genero, descricao, imagem_url, site_url)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO lancamentos (nome,plataformas,data_lancamento,genero,descricao,imagem_url,site_url) VALUES (%s,%s,%s,%s,%s,%s,%s)",
    escape(nome), escape(plataformas or ""), escape(data_lancamento or ""),
    escape(genero or ""), escape(descricao or ""),
    escape(imagem_url or ""), escape(site_url or "")
  ))
  return conn:last_insert_rowid()
end
 
function M.editar_lancamento(id, nome, plataformas, data_lancamento, genero, descricao, imagem_url, site_url)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE lancamentos SET nome=%s,plataformas=%s,data_lancamento=%s,genero=%s,descricao=%s,imagem_url=%s,site_url=%s WHERE id=%d",
    escape(nome), escape(plataformas or ""), escape(data_lancamento or ""),
    escape(genero or ""), escape(descricao or ""),
    escape(imagem_url or ""), escape(site_url or ""),
    tonumber(id)
  ))
end
 
function M.deletar_lancamento(id)
  local conn = M.connect()
  conn:exec("DELETE FROM lancamentos WHERE id=" .. tonumber(id))
end
 
-- ─── Diff de histórico ────────────────────────────────────────────────────────
 
-- Retorna diff palavra-a-palavra entre dois textos
-- Retorna tabela de tokens: { texto, tipo } onde tipo = "igual"|"add"|"del"
function M.diff_texto(texto_a, texto_b)
  -- Tokeniza em palavras
  local function tokenizar(s)
    local t = {}
    for w in (s .. " "):gmatch("([^%s]+)%s") do table.insert(t, w) end
    return t
  end
 
  local a = tokenizar(texto_a or "")
  local b = tokenizar(texto_b or "")
 
  -- LCS (Longest Common Subsequence) simplificado
  local m, n = #a, #b
  local dp = {}
  for i = 0, m do
    dp[i] = {}
    for j = 0, n do dp[i][j] = 0 end
  end
  for i = 1, m do
    for j = 1, n do
      if a[i] == b[j] then
        dp[i][j] = dp[i-1][j-1] + 1
      else
        dp[i][j] = math.max(dp[i-1][j], dp[i][j-1])
      end
    end
  end
 
  -- Reconstrói o diff
  local resultado = {}
  local i, j = m, n
  while i > 0 or j > 0 do
    if i > 0 and j > 0 and a[i] == b[j] then
      table.insert(resultado, 1, { texto = a[i], tipo = "igual" })
      i = i - 1; j = j - 1
    elseif j > 0 and (i == 0 or dp[i][j-1] >= dp[i-1][j]) then
      table.insert(resultado, 1, { texto = b[j], tipo = "add" })
      j = j - 1
    else
      table.insert(resultado, 1, { texto = a[i], tipo = "del" })
      i = i - 1
    end
  end
 
  return resultado
end
 
-- Compara dois snapshots do histórico pelo ID
function M.comparar_historico(id_a, id_b)
  local a = query("SELECT * FROM historico_edicoes WHERE id=" .. tonumber(id_a))[1]
  local b = query("SELECT * FROM historico_edicoes WHERE id=" .. tonumber(id_b))[1]
  if not a or not b then return nil end
 
  return {
    a            = a,
    b            = b,
    diff_titulo  = M.diff_texto(a.titulo_ant,   b.titulo_ant),
    diff_conteudo = M.diff_texto(a.conteudo_ant, b.conteudo_ant),
  }
end

-- ─── Histórico de leituras ────────────────────────────────────────────────────
 
-- Registra uma leitura (ignora duplicata — UNIQUE garante 1 por notícia)
function M.registrar_leitura(leitor_id, noticia_id)
  if not leitor_id or leitor_id == "" then return end
  local conn = M.connect()
  -- INSERT OR REPLACE para atualizar o timestamp se já existir
  conn:exec(string.format(
    "INSERT OR REPLACE INTO historico_leituras (leitor_id, noticia_id, lido_em) VALUES (%s, %d, datetime('now'))",
    escape(leitor_id), tonumber(noticia_id)
  ))
end
 
-- Retorna histórico de leituras de um leitor (notícias completas, paginado)
function M.get_historico_leituras(leitor_id, pagina, por_pagina)
  if not leitor_id or leitor_id == "" then return { rows = {}, total = 0, total_paginas = 0, pagina = 1 } end
  pagina     = tonumber(pagina)     or 1
  por_pagina = tonumber(por_pagina) or 12
  local total  = query(string.format(
    "SELECT COUNT(*) AS n FROM historico_leituras WHERE leitor_id = %s",
    escape(leitor_id)
  ))[1].n
  local offset = (pagina - 1) * por_pagina
  local rows   = query(string.format([[
    SELECT n.*, hl.lido_em
    FROM historico_leituras hl
    JOIN noticias n ON n.id = hl.noticia_id
    WHERE hl.leitor_id = %s
    ORDER BY hl.lido_em DESC
    LIMIT %d OFFSET %d
  ]], escape(leitor_id), por_pagina, offset))
  return {
    rows          = rows,
    total         = total,
    pagina        = pagina,
    por_pagina    = por_pagina,
    total_paginas = math.ceil(total / por_pagina),
  }
end
 
-- Categorias mais lidas por um leitor
function M.get_categorias_preferidas(leitor_id)
  if not leitor_id or leitor_id == "" then return {} end
  return query(string.format([[
    SELECT n.categoria, COUNT(*) AS total
    FROM historico_leituras hl
    JOIN noticias n ON n.id = hl.noticia_id
    WHERE hl.leitor_id = %s
    GROUP BY n.categoria
    ORDER BY total DESC
    LIMIT 5
  ]], escape(leitor_id)))
end
 
-- ─── Enquetes / Polls ─────────────────────────────────────────────────────────
 
-- Retorna enquete com opções e total de votos
function M.get_enquete(id)
  local enq = query("SELECT * FROM enquetes WHERE id=" .. tonumber(id))[1]
  if not enq then return nil end
  enq.opcoes = query("SELECT * FROM enquete_opcoes WHERE enquete_id=" .. tonumber(id) .. " ORDER BY id")
  local total_row = query("SELECT SUM(votos) AS t FROM enquete_opcoes WHERE enquete_id=" .. tonumber(id))[1]
  enq.total_votos = tonumber(total_row and total_row.t) or 0
  return enq
end
 
-- Retorna enquete associada a uma notícia
function M.get_enquete_da_noticia(noticia_id)
  local rows = query(string.format(
    "SELECT id FROM enquetes WHERE noticia_id=%d AND ativa=1 LIMIT 1",
    tonumber(noticia_id)
  ))
  if #rows == 0 then return nil end
  return M.get_enquete(rows[1].id)
end
 
-- Lista todas as enquetes (para o admin)
function M.get_enquetes()
  return query([[
    SELECT e.*, n.titulo AS noticia_titulo,
      (SELECT SUM(votos) FROM enquete_opcoes WHERE enquete_id=e.id) AS total_votos
    FROM enquetes e
    LEFT JOIN noticias n ON n.id = e.noticia_id
    ORDER BY e.criado_em DESC
  ]])
end
 
-- Cria uma enquete com suas opções
function M.criar_enquete(noticia_id, pergunta, opcoes)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO enquetes (noticia_id, pergunta) VALUES (%s, %s)",
    noticia_id and tostring(tonumber(noticia_id)) or "NULL",
    escape(pergunta)
  ))
  local enq_id = conn:last_insert_rowid()
  for _, texto in ipairs(opcoes or {}) do
    if texto ~= "" then
      conn:exec(string.format(
        "INSERT INTO enquete_opcoes (enquete_id, texto) VALUES (%d, %s)",
        enq_id, escape(texto)
      ))
    end
  end
  return enq_id
end
 
-- Registra voto (retorna "ok", "ja_votou" ou "erro")
function M.votar_enquete(enquete_id, opcao_id, ip)
  local conn = M.connect()
  -- Verifica se já votou
  local ja = query(string.format(
    "SELECT id FROM enquete_votos WHERE enquete_id=%d AND ip=%s LIMIT 1",
    tonumber(enquete_id), escape(ip)
  ))
  if #ja > 0 then return "ja_votou" end
 
  -- Verifica se opção pertence à enquete
  local opcao = query(string.format(
    "SELECT id FROM enquete_opcoes WHERE id=%d AND enquete_id=%d LIMIT 1",
    tonumber(opcao_id), tonumber(enquete_id)
  ))
  if #opcao == 0 then return "erro" end
 
  -- Registra voto e incrementa contador
  conn:exec(string.format(
    "INSERT INTO enquete_votos (enquete_id, opcao_id, ip) VALUES (%d, %d, %s)",
    tonumber(enquete_id), tonumber(opcao_id), escape(ip)
  ))
  conn:exec(string.format(
    "UPDATE enquete_opcoes SET votos=votos+1 WHERE id=%d",
    tonumber(opcao_id)
  ))
  return "ok"
end
 
-- Deleta enquete
function M.deletar_enquete(id)
  local conn = M.connect()
  conn:exec("DELETE FROM enquetes WHERE id=" .. tonumber(id))
end
 
-- ─── Performance ─────────────────────────────────────────────────────────────
 
-- Registra uma requisição (chame no início+fim de rotas importantes)
function M.log_perf(rota, metodo, status, ms)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO perf_log (rota, metodo, status, ms) VALUES (%s, %s, %d, %d)",
    escape(rota), escape(metodo or "GET"),
    tonumber(status) or 200, tonumber(ms) or 0
  ))
end
 
-- Estatísticas de performance por rota (últimas 24h)
function M.get_perf_stats(horas)
  horas = tonumber(horas) or 24
  return query(string.format([[
    SELECT
      rota,
      COUNT(*)              AS requests,
      ROUND(AVG(ms), 1)     AS avg_ms,
      MAX(ms)               AS max_ms,
      MIN(ms)               AS min_ms,
      SUM(CASE WHEN status >= 400 THEN 1 ELSE 0 END) AS erros,
      SUM(CASE WHEN ms > 500  THEN 1 ELSE 0 END)     AS lentas
    FROM perf_log
    WHERE criado_em >= datetime('now', '-%d hours')
    GROUP BY rota
    ORDER BY requests DESC
  ]], horas))
end
 
-- Série temporal de requests por hora (últimas 24h)
function M.get_perf_por_hora()
  return query([[
    SELECT
      strftime('%H', criado_em) AS hora,
      COUNT(*)                  AS requests,
      ROUND(AVG(ms), 0)         AS avg_ms
    FROM perf_log
    WHERE criado_em >= datetime('now', '-24 hours')
    GROUP BY hora
    ORDER BY hora ASC
  ]])
end
 
-- Erros recentes (status >= 400)
function M.get_erros_recentes(limite)
  return query(string.format([[
    SELECT rota, status, ms, criado_em
    FROM perf_log
    WHERE status >= 400
    ORDER BY criado_em DESC
    LIMIT %d
  ]], tonumber(limite) or 20))
end
 
-- Limpa logs antigos
function M.limpar_perf_log(horas)
  local conn = M.connect()
  conn:exec(string.format(
    "DELETE FROM perf_log WHERE criado_em < datetime('now', '-%d hours')",
    tonumber(horas) or 168  -- 7 dias padrão
  ))
end
 
-- ─── Widget "você também pode gostar" (por tags) ──────────────────────────────
 
-- Retorna notícias que compartilham tags com a notícia atual
-- Mais refinado que get_noticias_relacionadas: usa score de tags em comum
function M.get_voce_pode_gostar(noticia_id, limite)
  noticia_id = tonumber(noticia_id)
  limite     = tonumber(limite) or 4
 
  -- Busca notícias que têm tags em comum, ordenadas por score
  local resultado = query(string.format([[
    SELECT n.id, n.titulo, n.categoria, n.jogo, n.criado_em,
           n.imagem_url, n.views, n.destaque,
           COUNT(nt2.tag_id) AS tags_comuns
    FROM noticia_tags nt1
    JOIN noticia_tags nt2 ON nt2.tag_id = nt1.tag_id AND nt2.noticia_id != %d
    JOIN noticias n ON n.id = nt2.noticia_id
    WHERE nt1.noticia_id = %d
      AND (n.publicar_em = '' OR n.publicar_em <= datetime('now'))
    GROUP BY n.id
    ORDER BY tags_comuns DESC, n.views DESC, n.criado_em DESC
    LIMIT %d
  ]], noticia_id, noticia_id, limite))
 
  -- Se não tiver tags em comum, fallback para categoria
  if #resultado == 0 then
    local noticia = M.get_noticia(noticia_id)
    if noticia then
      resultado = query(string.format([[
        SELECT id, titulo, categoria, jogo, criado_em, imagem_url, views, destaque,
               0 AS tags_comuns
        FROM noticias
        WHERE categoria = %s AND id != %d
          AND (publicar_em = '' OR publicar_em <= datetime('now'))
        ORDER BY views DESC, criado_em DESC
        LIMIT %d
      ]], escape(noticia.categoria), noticia_id, limite))
    end
  end
 
  return resultado
end
 
-- ─── Comparação de jogos ──────────────────────────────────────────────────────
 
-- Retorna dados enriquecidos de dois jogos para comparação
function M.comparar_jogos(id_a, id_b)
  local a = M.get_jogo(id_a)
  local b = M.get_jogo(id_b)
  if not a or not b then return nil end
 
  -- Enriquece com avaliações
  local aval_a = M.get_avaliacao_jogo(id_a)
  local aval_b = M.get_avaliacao_jogo(id_b)
  a.media_aval = aval_a.media; a.total_avals = aval_a.total
  b.media_aval = aval_b.media; b.total_avals = aval_b.total
 
  -- Contagem de notícias sobre cada jogo
  local n_a = query(string.format(
    "SELECT COUNT(*) AS n FROM noticias WHERE jogo=%s", escape(a.nome)
  ))[1].n
  local n_b = query(string.format(
    "SELECT COUNT(*) AS n FROM noticias WHERE jogo=%s", escape(b.nome)
  ))[1].n
  a.total_noticias = n_a
  b.total_noticias = n_b
 
  -- Views totais das notícias de cada jogo
  local v_a = query(string.format(
    "SELECT COALESCE(SUM(views),0) AS n FROM noticias WHERE jogo=%s", escape(a.nome)
  ))[1].n
  local v_b = query(string.format(
    "SELECT COALESCE(SUM(views),0) AS n FROM noticias WHERE jogo=%s", escape(b.nome)
  ))[1].n
  a.views_noticias = v_a
  b.views_noticias = v_b
 
  -- Curtidas totais nas notícias
  local l_a = query(string.format(
    "SELECT COALESCE(SUM(likes),0) AS n FROM noticias WHERE jogo=%s", escape(a.nome)
  ))[1].n
  local l_b = query(string.format(
    "SELECT COALESCE(SUM(likes),0) AS n FROM noticias WHERE jogo=%s", escape(b.nome)
  ))[1].n
  a.likes_noticias = l_a
  b.likes_noticias = l_b
 
  -- Última notícia de cada jogo
  local ul_a = query(string.format(
    "SELECT titulo, criado_em FROM noticias WHERE jogo=%s ORDER BY criado_em DESC LIMIT 1",
    escape(a.nome)
  ))[1]
  local ul_b = query(string.format(
    "SELECT titulo, criado_em FROM noticias WHERE jogo=%s ORDER BY criado_em DESC LIMIT 1",
    escape(b.nome)
  ))[1]
  a.ultima_noticia = ul_a
  b.ultima_noticia = ul_b
 
  return { a = a, b = b }
end

-- âââ Leitores / ConfiguraÃ§Ãµes ââââââââââââââââââââââââââââââââ

-- ─── Leitores / Configurações ─────────────────────────────────

function M.get_leitor_config(leitor_id)
  -- Garante que a coluna 'nome' existe
  local conn = M.connect()
  pcall(function() conn:exec("ALTER TABLE leitores ADD COLUMN nome TEXT") end)

  local rows = query(string.format("SELECT * FROM leitores WHERE leitor_id = %s", escape(leitor_id)))
  if rows[1] then return rows[1] end
  -- Se não existe, cria com padrão
  conn:exec(string.format("INSERT OR IGNORE INTO leitores (leitor_id) VALUES (%s)", escape(leitor_id)))
  return { leitor_id = leitor_id, avatar = '👤', nome = nil }
end

function M.set_leitor_avatar(leitor_id, avatar)
  local conn = M.connect()
  -- Garante que o leitor existe antes de dar update
  conn:exec(string.format("INSERT OR IGNORE INTO leitores (leitor_id) VALUES (%s)", escape(leitor_id)))
  conn:exec(string.format(
    "UPDATE leitores SET avatar = %s WHERE leitor_id = %s",
    escape(avatar), escape(leitor_id)
  ))
end

function M.set_leitor_nome(leitor_id, nome)
  local conn = M.connect()
  -- Garante que o leitor existe antes de dar update
  conn:exec(string.format("INSERT OR IGNORE INTO leitores (leitor_id) VALUES (%s)", escape(leitor_id)))
  conn:exec(string.format(
    "UPDATE leitores SET nome = %s WHERE leitor_id = %s",
    escape(nome), escape(leitor_id)
  ))
end

function M.limpar_historico_leituras(leitor_id)
  local conn = M.connect()
  conn:exec(string.format("DELETE FROM historico_leituras WHERE leitor_id = %s", escape(leitor_id)))
end

-- ─── Notas Rápidas ────────────────────────────────────────────────────────────

function M.get_nota_rapida(leitor_id, noticia_id)
  if not leitor_id or leitor_id == "" then return nil end
  local rows = query(string.format(
    "SELECT * FROM notas_rapidas WHERE leitor_id=%s AND noticia_id=%d LIMIT 1",
    escape(leitor_id), tonumber(noticia_id)
  ))
  return rows[1]
end

function M.salvar_nota_rapida(leitor_id, noticia_id, texto)
  if not leitor_id or leitor_id == "" then return false end
  local conn = M.connect()
  conn:exec(string.format([[
    INSERT INTO notas_rapidas (leitor_id, noticia_id, texto, atualizado_em)
    VALUES (%s, %d, %s, datetime('now'))
    ON CONFLICT(leitor_id, noticia_id) DO UPDATE
    SET texto=%s, atualizado_em=datetime('now')
  ]], escape(leitor_id), tonumber(noticia_id), escape(texto), escape(texto)))
  return true
end

function M.deletar_nota_rapida(leitor_id, noticia_id)
  local conn = M.connect()
  conn:exec(string.format(
    "DELETE FROM notas_rapidas WHERE leitor_id=%s AND noticia_id=%d",
    escape(leitor_id), tonumber(noticia_id)
  ))
end

function M.get_notas_leitor(leitor_id)
  if not leitor_id or leitor_id == "" then return {} end
  return query(string.format([[
    SELECT nr.*, n.titulo AS noticia_titulo, n.categoria, n.jogo
    FROM notas_rapidas nr
    JOIN noticias n ON n.id = nr.noticia_id
    WHERE nr.leitor_id = %s
    ORDER BY nr.atualizado_em DESC
  ]], escape(leitor_id)))
end

-- ─── Crônicas / Editoriais ────────────────────────────────────────────────────

function M.get_cronicas(apenas_publicadas)
  if apenas_publicadas then
    return query([[
      SELECT c.*, a.nome AS autor_nome, a.avatar_url AS autor_avatar
      FROM cronicas c
      LEFT JOIN autores a ON a.id = c.autor_id
      WHERE c.publicar_em = '' OR c.publicar_em <= datetime('now')
      ORDER BY c.destaque DESC, c.criado_em DESC
    ]])
  end
  return query([[
    SELECT c.*, a.nome AS autor_nome, a.avatar_url AS autor_avatar
    FROM cronicas c
    LEFT JOIN autores a ON a.id = c.autor_id
    ORDER BY c.criado_em DESC
  ]])
end

function M.get_cronica(id)
  local rows = query(string.format([[
    SELECT c.*, a.nome AS autor_nome, a.avatar_url AS autor_avatar
    FROM cronicas c
    LEFT JOIN autores a ON a.id = c.autor_id
    WHERE c.id = %d
  ]], tonumber(id)))
  return rows[1]
end

function M.criar_cronica(titulo, subtitulo, conteudo, autor_id, imagem_url, tags_str, destaque, publicar_em)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO cronicas (titulo,subtitulo,conteudo,autor_id,imagem_url,tags_str,destaque,publicar_em) VALUES (%s,%s,%s,%s,%s,%s,%d,%s)",
    escape(titulo), escape(subtitulo or ""), escape(conteudo),
    autor_id and tostring(tonumber(autor_id)) or "NULL",
    escape(imagem_url or ""), escape(tags_str or ""),
    destaque and 1 or 0, escape(publicar_em or "")
  ))
  return conn:last_insert_rowid()
end

function M.editar_cronica(id, titulo, subtitulo, conteudo, autor_id, imagem_url, tags_str, destaque, publicar_em)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE cronicas SET titulo=%s,subtitulo=%s,conteudo=%s,autor_id=%s,imagem_url=%s,tags_str=%s,destaque=%d,publicar_em=%s WHERE id=%d",
    escape(titulo), escape(subtitulo or ""), escape(conteudo),
    autor_id and tostring(tonumber(autor_id)) or "NULL",
    escape(imagem_url or ""), escape(tags_str or ""),
    destaque and 1 or 0, escape(publicar_em or ""),
    tonumber(id)
  ))
end

function M.deletar_cronica(id)
  local conn = M.connect()
  conn:exec("DELETE FROM cronicas WHERE id=" .. tonumber(id))
end

function M.incrementar_views_cronica(id)
  local conn = M.connect()
  conn:exec("UPDATE cronicas SET views=views+1 WHERE id=" .. tonumber(id))
end

-- ─── Exportação CSV ───────────────────────────────────────────────────────────

function M.exportar_noticias_csv()
  local rows = query([[
    SELECT n.id, n.titulo, n.categoria, n.jogo, n.destaque, n.views,
           n.likes, n.dislikes, n.criado_em, a.nome AS autor
    FROM noticias n
    LEFT JOIN autores a ON a.id = n.autor_id
    ORDER BY n.criado_em DESC
  ]])
  local linhas = { "id,titulo,categoria,jogo,destaque,views,likes,dislikes,autor,criado_em" }
  for _, r in ipairs(rows) do
    local function csv_field(v)
      v = tostring(v or "")
      if v:find('[",\n]') then v = '"' .. v:gsub('"', '""') .. '"' end
      return v
    end
    table.insert(linhas, table.concat({
      csv_field(r.id), csv_field(r.titulo), csv_field(r.categoria),
      csv_field(r.jogo), csv_field(r.destaque), csv_field(r.views),
      csv_field(r.likes or 0), csv_field(r.dislikes or 0),
      csv_field(r.autor or ""), csv_field(r.criado_em)
    }, ","))
  end
  return table.concat(linhas, "\n")
end

function M.exportar_comentarios_csv()
  local rows = query([[
    SELECT c.id, c.autor, c.conteudo, c.aprovado, c.criado_em,
           n.titulo AS noticia_titulo
    FROM comentarios c
    JOIN noticias n ON n.id = c.noticia_id
    ORDER BY c.criado_em DESC
  ]])
  local linhas = { "id,autor,conteudo,aprovado,noticia,criado_em" }
  for _, r in ipairs(rows) do
    local function csv_field(v)
      v = tostring(v or "")
      if v:find('[",\n]') then v = '"' .. v:gsub('"', '""') .. '"' end
      return v
    end
    table.insert(linhas, table.concat({
      csv_field(r.id), csv_field(r.autor), csv_field(r.conteudo),
      csv_field(r.aprovado), csv_field(r.noticia_titulo), csv_field(r.criado_em)
    }, ","))
  end
  return table.concat(linhas, "\n")
end

function M.exportar_newsletter_csv()
  local rows = query("SELECT id, email, criado_em FROM newsletter WHERE ativo=1 ORDER BY criado_em DESC")
  local linhas = { "id,email,criado_em" }
  for _, r in ipairs(rows) do
    table.insert(linhas, tostring(r.id) .. "," .. r.email .. "," .. r.criado_em)
  end
  return table.concat(linhas, "\n")
end

-- ─── Tempo de leitura estimado ────────────────────────────────────────────────

function M.tempo_leitura(texto)
  local palavras = 0
  for _ in (texto or ""):gmatch("%S+") do palavras = palavras + 1 end
  return math.max(1, math.ceil(palavras / 200))
end


-- ─── Glossário ────────────────────────────────────────────────────────────────

function M.get_glossario()
  return query("SELECT * FROM glossario ORDER BY termo ASC")
end

function M.get_glossario_por_letra(letra)
  return query(string.format(
    "SELECT * FROM glossario WHERE termo LIKE %s ORDER BY termo ASC",
    escape(letra .. "%")
  ))
end

function M.get_termo(id)
  local rows = query("SELECT * FROM glossario WHERE id=" .. tonumber(id))
  return rows[1]
end

function M.buscar_glossario(q)
  local t = escape("%" .. (q or "") .. "%")
  return query(string.format(
    "SELECT * FROM glossario WHERE termo LIKE %s OR definicao LIKE %s ORDER BY termo ASC",
    t, t
  ))
end

function M.criar_termo(termo, definicao, categoria)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO glossario (termo, definicao, categoria) VALUES (%s, %s, %s)",
    escape(termo), escape(definicao or ""), escape(categoria or "Geral")
  ))
  return conn:last_insert_rowid()
end

function M.editar_termo(id, termo, definicao, categoria)
  local conn = M.connect()
  conn:exec(string.format(
    "UPDATE glossario SET termo=%s, definicao=%s, categoria=%s WHERE id=%d",
    escape(termo), escape(definicao or ""), escape(categoria or "Geral"), tonumber(id)
  ))
end

function M.deletar_termo(id)
  local conn = M.connect()
  conn:exec("DELETE FROM glossario WHERE id=" .. tonumber(id))
end

-- ─── A/B Test ─────────────────────────────────────────────────────────────────

function M.get_ab_testes()
  return query([[
    SELECT ab.*, n.titulo AS titulo_a
    FROM ab_testes ab
    JOIN noticias n ON n.id = ab.noticia_id
    ORDER BY ab.criado_em DESC
  ]])
end

function M.get_ab_teste(noticia_id)
  local rows = query(string.format(
    "SELECT * FROM ab_testes WHERE noticia_id=%d AND ativo=1 LIMIT 1",
    tonumber(noticia_id)
  ))
  return rows[1]
end

function M.criar_ab_teste(noticia_id, titulo_b)
  local conn = M.connect()
  conn:exec("UPDATE ab_testes SET ativo=0 WHERE noticia_id=" .. tonumber(noticia_id))
  conn:exec(string.format(
    "INSERT INTO ab_testes (noticia_id, titulo_b) VALUES (%d, %s)",
    tonumber(noticia_id), escape(titulo_b)
  ))
  return conn:last_insert_rowid()
end

function M.registrar_view_ab(teste_id, variante)
  local conn = M.connect()
  local col = variante == "b" and "views_b" or "views_a"
  conn:exec(string.format(
    "UPDATE ab_testes SET %s=%s+1 WHERE id=%d",
    col, col, tonumber(teste_id)
  ))
end

function M.deletar_ab_teste(id)
  local conn = M.connect()
  conn:exec("DELETE FROM ab_testes WHERE id=" .. tonumber(id))
end

-- ─── Citações ─────────────────────────────────────────────────────────────────

function M.get_citacoes()
  return query("SELECT * FROM citacoes ORDER BY criado_em DESC")
end

function M.get_citacao_aleatoria()
  local rows = query("SELECT * FROM citacoes ORDER BY RANDOM() LIMIT 1")
  return rows[1]
end

function M.criar_citacao(texto, personagem, jogo)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO citacoes (texto, personagem, jogo) VALUES (%s, %s, %s)",
    escape(texto), escape(personagem or ""), escape(jogo or "")
  ))
  return conn:last_insert_rowid()
end

function M.deletar_citacao(id)
  local conn = M.connect()
  conn:exec("DELETE FROM citacoes WHERE id=" .. tonumber(id))
end

-- ─── Feed personalizado ───────────────────────────────────────────────────────

function M.get_feed_personalizado(leitor_id, limite)
  limite = tonumber(limite) or 10
  if not leitor_id or leitor_id == "" then
    return query(string.format([[
      SELECT * FROM noticias
      WHERE publicar_em = '' OR publicar_em <= datetime('now')
      ORDER BY views DESC, criado_em DESC LIMIT %d
    ]], limite))
  end
  local cats = query(string.format([[
    SELECT n.categoria, COUNT(*) AS peso
    FROM historico_leituras hl
    JOIN noticias n ON n.id = hl.noticia_id
    WHERE hl.leitor_id = %s
    GROUP BY n.categoria ORDER BY peso DESC LIMIT 3
  ]], escape(leitor_id)))
  local tags = query(string.format([[
    SELECT t.nome, COUNT(*) AS peso
    FROM historico_leituras hl
    JOIN noticia_tags nt ON nt.noticia_id = hl.noticia_id
    JOIN tags t ON t.id = nt.tag_id
    WHERE hl.leitor_id = %s
    GROUP BY t.nome ORDER BY peso DESC LIMIT 5
  ]], escape(leitor_id)))
  local lidos = query(string.format(
    "SELECT noticia_id FROM historico_leituras WHERE leitor_id=%s", escape(leitor_id)
  ))
  local lidos_ids = {}
  for _, r in ipairs(lidos) do lidos_ids[r.noticia_id] = true end
  local candidatas, vistas = {}, {}
  for _, cat in ipairs(cats) do
    local rows = query(string.format([[
      SELECT *, %d AS relevancia FROM noticias
      WHERE categoria=%s AND (publicar_em='' OR publicar_em<=datetime('now'))
      ORDER BY views DESC, criado_em DESC LIMIT 20
    ]], cat.peso*3, escape(cat.categoria)))
    for _, n in ipairs(rows) do
      if not lidos_ids[n.id] and not vistas[n.id] then
        vistas[n.id]=true; table.insert(candidatas, n)
      end
    end
  end
  for _, tag in ipairs(tags) do
    local rows = query(string.format([[
      SELECT n.*, %d AS relevancia FROM noticias n
      JOIN noticia_tags nt ON nt.noticia_id=n.id
      JOIN tags t ON t.id=nt.tag_id
      WHERE t.nome=%s AND (n.publicar_em='' OR n.publicar_em<=datetime('now'))
      ORDER BY n.views DESC LIMIT 10
    ]], tag.peso*2, escape(tag.nome)))
    for _, n in ipairs(rows) do
      if not lidos_ids[n.id] and not vistas[n.id] then
        vistas[n.id]=true; table.insert(candidatas, n)
      end
    end
  end
  table.sort(candidatas, function(a,b) return (a.relevancia or 0)>(b.relevancia or 0) end)
  if #candidatas < limite then
    local extras = query(string.format([[
      SELECT * FROM noticias
      WHERE publicar_em='' OR publicar_em<=datetime('now')
      ORDER BY criado_em DESC LIMIT %d
    ]], limite*2))
    for _, n in ipairs(extras) do
      if not lidos_ids[n.id] and not vistas[n.id] then
        vistas[n.id]=true; table.insert(candidatas, n)
        if #candidatas>=limite then break end
      end
    end
  end
  local resultado = {}
  for i=1,math.min(limite,#candidatas) do table.insert(resultado, candidatas[i]) end
  return resultado
end

-- ─── Galeria de imagens dos jogos ────────────────────────────────────────────

function M.get_galeria_jogo(jogo_id)
  return query(string.format(
    "SELECT * FROM galeria WHERE jogo_id=%d ORDER BY criado_em DESC",
    tonumber(jogo_id)
  ))
end

function M.get_galeria_todas()
  return query([[
    SELECT g.*, j.nome AS jogo_nome
    FROM galeria g
    JOIN jogos j ON j.id = g.jogo_id
    ORDER BY g.criado_em DESC
  ]])
end

function M.adicionar_imagem_galeria(jogo_id, url, legenda)
  local conn = M.connect()
  conn:exec(string.format(
    "INSERT INTO galeria (jogo_id, url, legenda) VALUES (%d, %s, %s)",
    tonumber(jogo_id), escape(url), escape(legenda or "")
  ))
  return conn:last_insert_rowid()
end

function M.deletar_imagem_galeria(id)
  local conn = M.connect()
  conn:exec("DELETE FROM galeria WHERE id=" .. tonumber(id))
end

-- ─── Favoritos / Bookmarks ────────────────────────────────────────────────────

function M.get_favoritos(leitor_id)
  if not leitor_id or leitor_id == "" then return {} end
  return query(string.format([[
    SELECT n.*, f.criado_em AS favoritado_em
    FROM favoritos f
    JOIN noticias n ON n.id = f.noticia_id
    WHERE f.leitor_id = %s
    ORDER BY f.criado_em DESC
  ]], escape(leitor_id)))
end

function M.is_favorito(leitor_id, noticia_id)
  if not leitor_id or leitor_id == "" then return false end
  local rows = query(string.format(
    "SELECT id FROM favoritos WHERE leitor_id=%s AND noticia_id=%d LIMIT 1",
    escape(leitor_id), tonumber(noticia_id)
  ))
  return #rows > 0
end

function M.toggle_favorito(leitor_id, noticia_id)
  if not leitor_id or leitor_id == "" then return false end
  local conn = M.connect()
  if M.is_favorito(leitor_id, noticia_id) then
    conn:exec(string.format(
      "DELETE FROM favoritos WHERE leitor_id=%s AND noticia_id=%d",
      escape(leitor_id), tonumber(noticia_id)
    ))
    return false  -- removido
  else
    conn:exec(string.format(
      "INSERT INTO favoritos (leitor_id, noticia_id) VALUES (%s, %d)",
      escape(leitor_id), tonumber(noticia_id)
    ))
    return true   -- adicionado
  end
end

function M.count_favoritos(leitor_id)
  if not leitor_id or leitor_id == "" then return 0 end
  local r = query(string.format(
    "SELECT COUNT(*) AS n FROM favoritos WHERE leitor_id=%s", escape(leitor_id)
  ))
  return r[1] and r[1].n or 0
end

function M.limpar_favoritos(leitor_id)
  if not leitor_id or leitor_id == "" then return end
  local conn = M.connect()
  conn:exec(string.format("DELETE FROM favoritos WHERE leitor_id=%s", escape(leitor_id)))
end

-- ─── Calendário de agendamento ────────────────────────────────────────────────

-- Retorna notícias agendadas para um mês específico
function M.get_calendario(ano, mes)
  local inicio = string.format("%04d-%02d-01", ano, mes)
  local fim    = string.format("%04d-%02d-31", ano, mes)
  return query(string.format([[
    SELECT id, titulo, publicar_em, destaque, categoria
    FROM noticias
    WHERE publicar_em != '' AND publicar_em BETWEEN %s AND %s
    ORDER BY publicar_em ASC
  ]], escape(inicio), escape(fim .. " 23:59:59")))
end

-- Retorna notícias publicadas em um mês (para o calendário)
function M.get_calendario_publicadas(ano, mes)
  local inicio = string.format("%04d-%02d-01", ano, mes)
  local fim    = string.format("%04d-%02d-31", ano, mes)
  return query(string.format([[
    SELECT id, titulo, criado_em, destaque, categoria
    FROM noticias
    WHERE (publicar_em='' OR publicar_em<=datetime('now'))
      AND criado_em BETWEEN %s AND %s
    ORDER BY criado_em ASC
  ]], escape(inicio), escape(fim .. " 23:59:59")))
end


return M