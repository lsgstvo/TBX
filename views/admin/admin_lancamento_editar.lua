-- views/admin/admin_lancamento_editar.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local l = self.lancamento or {}
  div({ class = "admin-section shadow-card" }, function()
    h2("✏️ Editar Lançamento")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end
    form({ method = "POST",
           action  = "/admin/lancamentos/" .. l.id .. "/editar",
           class   = "admin-form" }, function()

      div({ class = "form-group" }, function()
        label({ ["for"] = "nome" }, "Nome do Jogo *")
        input({ type = "text", id = "nome", name = "nome",
                value = l.nome or "", required = true })
      end)
      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "plataformas" }, "Plataformas")
          input({ type = "text", id = "plataformas", name = "plataformas",
                  value = l.plataformas or "", placeholder = "Ex: PS5, Xbox, PC" })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "data_lancamento" }, "Data de Lançamento")
          input({ type = "date", id = "data_lancamento", name = "data_lancamento",
                  value = l.data_lancamento or "" })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "genero" }, "Gênero")
          input({ type = "text", id = "genero", name = "genero",
                  value = l.genero or "", placeholder = "Ex: RPG de Ação" })
        end)
      end)
      div({ class = "form-group" }, function()
        label({ ["for"] = "imagem_url" }, "URL da Imagem")
        input({ type = "url", id = "imagem_url", name = "imagem_url",
                value = l.imagem_url or "" })
        if l.imagem_url and l.imagem_url ~= "" then
          div({ class = "img-preview", style = "margin-top:.4rem" }, function()
            img({ src = l.imagem_url, alt = l.nome,
                  style = "max-width:120px;border-radius:6px" })
          end)
        end
      end)
      div({ class = "form-group" }, function()
        label({ ["for"] = "site_url" }, "Site Oficial")
        input({ type = "url", id = "site_url", name = "site_url",
                value = l.site_url or "" })
      end)
      div({ class = "form-group" }, function()
        label({ ["for"] = "descricao" }, "Descrição")
        textarea({ id = "descricao", name = "descricao", rows = "3" },
                 l.descricao or "")
      end)

      div({ class = "form-actions" }, function()
        a({ href = "/admin/lancamentos", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Alterações")
      end)
    end)
  end)
end)