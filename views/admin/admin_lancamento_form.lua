-- views/admin/admin_lancamento_form.lua
local Widget = require("lapis.html").Widget

local function campos_lancamento(self, values)
  values = values or {}
  div({ class = "form-group" }, function()
    label({ ["for"] = "nome" }, "Nome do Jogo *")
    input({ type = "text", id = "nome", name = "nome",
            value = values.nome or "",
            placeholder = "Ex: GTA VII", required = true })
  end)
  div({ class = "form-row" }, function()
    div({ class = "form-group form-grow" }, function()
      label({ ["for"] = "plataformas" }, "Plataformas")
      input({ type = "text", id = "plataformas", name = "plataformas",
              value = values.plataformas or "",
              placeholder = "Ex: PS5, Xbox, PC" })
    end)
    div({ class = "form-group" }, function()
      label({ ["for"] = "data_lancamento" }, "Data de Lançamento")
      input({ type = "date", id = "data_lancamento", name = "data_lancamento",
              value = values.data_lancamento or "" })
    end)
    div({ class = "form-group" }, function()
      label({ ["for"] = "genero" }, "Gênero")
      input({ type = "text", id = "genero", name = "genero",
              value = values.genero or "",
              placeholder = "Ex: RPG de Ação" })
    end)
  end)
  div({ class = "form-group" }, function()
    label({ ["for"] = "imagem_url" }, "URL da Imagem")
    input({ type = "url", id = "imagem_url", name = "imagem_url",
            value = values.imagem_url or "",
            placeholder = "https://..." })
  end)
  div({ class = "form-group" }, function()
    label({ ["for"] = "site_url" }, "Site Oficial")
    input({ type = "url", id = "site_url", name = "site_url",
            value = values.site_url or "",
            placeholder = "https://..." })
  end)
  div({ class = "form-group" }, function()
    label({ ["for"] = "descricao" }, "Descrição")
    textarea({ id = "descricao", name = "descricao", rows = "3",
               placeholder = "Breve descrição do jogo..." },
             values.descricao or "")
  end)
end

-- ── Formulário Novo ──────────────────────────────────────────────────────────
return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("🎮 Novo Lançamento")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end
    form({ method = "POST", action = "/admin/lancamentos/novo",
           class  = "admin-form" }, function()
      campos_lancamento(self)
      div({ class = "form-actions" }, function()
        a({ href = "/admin/lancamentos", class = "btn-cancelar" }, "Cancelar")
        button({ type = "submit", class = "btn-salvar" }, "💾 Salvar")
      end)
    end)
  end)
end)