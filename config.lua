local config = require("lapis.config")

config("development", {
  server       = "nginx",
  code_cache   = "off",
  num_workers  = "1",

  -- Chave secreta para assinar os cookies de sessão
  -- IMPORTANTE: troque por uma string longa e aleatória em produção!
  secret = "troque_por_uma_chave_secreta_longa_aqui_2026",

  -- Credenciais do painel admin
  -- Altere para seu usuário e senha antes de subir para produção
  admin_user     = "Tibull",
  admin_password = "teste12345",
})