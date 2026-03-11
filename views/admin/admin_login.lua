-- Tela de login do painel administrativo

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "login-wrapper" }, function()
    div({ class = "login-card" }, function()
      div({ class = "login-header" }, function()
        h1("⚙️ Portal Gamer")
        p("Painel Administrativo")
      end)

      -- Mensagem de erro (login inválido)
      if self.erro then
        div({ class = "alert alert-erro" }, self.erro)
      end

      -- Formulário de login
      form({ method = "POST", action = "/admin/login", class = "login-form" }, function()
        div({ class = "form-group" }, function()
          label({ for = "usuario" }, "Usuário")
          input({ type = "text", id = "usuario", name = "usuario",
                  placeholder = "Digite seu usuário", autocomplete = "username", required = true })
        end)
        div({ class = "form-group" }, function()
          label({ for = "senha" }, "Senha")
          input({ type = "password", id = "senha", name = "senha",
                  placeholder = "Digite sua senha", autocomplete = "current-password", required = true })
        end)
        button({ type = "submit", class = "btn-login" }, "Entrar →")
      end)
    end)
  end)
end)