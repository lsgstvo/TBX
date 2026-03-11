-- Middleware de autenticação do painel admin.
-- Uso: chame auth.require_login(self) no início de cada rota protegida.

local config = require("lapis.config").get()

local M = {}

-- Verifica se o usuário está logado (sessão ativa)
function M.logged_in(self)
  return self.session.admin == true
end

-- Redireciona para login se não estiver autenticado
-- Retorna true se deve continuar, false se redirecionou
function M.require_login(self)
  if not M.logged_in(self) then
    return self:write({ redirect_to = "/admin/login" })
  end
  return true
end

-- Valida usuário e senha contra o config
function M.check_credentials(usuario, senha)
  return usuario == config.admin_user and senha == config.admin_password
end

return M