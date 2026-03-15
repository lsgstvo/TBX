-- views/admin/admin_historico_diff.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("🕓 Histórico de Edições — " .. self.noticia.titulo)

    -- Seletor de versões para comparar
    if self.historico and #self.historico >= 2 then
      div({ class = "diff-seletor shadow-card" }, function()
        h3("Selecione duas versões para comparar:")
        form({ method = "GET",
               action  = "/admin/noticias/" .. self.noticia.id .. "/historico",
               class   = "diff-form" }, function()
          div({ class = "form-row" }, function()
            div({ class = "form-group" }, function()
              label({ ["for"] = "a" }, "Versão A (antiga)")
              element("select", { id = "a", name = "a" }, function()
                for _, h in ipairs(self.historico) do
                  local attrs = { value = tostring(h.id) }
                  if self.comparacao and self.comparacao.a
                    and self.comparacao.a.id == h.id then
                    attrs.selected = true
                  end
                  option(attrs, h.editado_em:sub(1,16) .. " — " .. h.titulo_ant:sub(1,40))
                end
              end)
            end)
            div({ class = "form-group" }, function()
              label({ ["for"] = "b" }, "Versão B (nova)")
              element("select", { id = "b", name = "b" }, function()
                for i, h in ipairs(self.historico) do
                  local attrs = { value = tostring(h.id) }
                  if i == 1 then attrs.selected = true end
                  if self.comparacao and self.comparacao.b
                    and self.comparacao.b.id == h.id then
                    attrs.selected = true
                  end
                  option(attrs, h.editado_em:sub(1,16) .. " — " .. h.titulo_ant:sub(1,40))
                end
              end)
            end)
          end)
          button({ type = "submit", class = "btn-salvar" }, "🔍 Comparar")
        end)
      end)
    end

    -- Resultado do diff
    if self.comparacao then
      local comp = self.comparacao

      div({ class = "diff-resultado shadow-card mt-2" }, function()
        div({ class = "diff-meta" }, function()
          div({ class = "diff-versao diff-versao-a" }, function()
            span({ class = "diff-versao-label" }, "Versão A")
            span({ class = "diff-versao-data" }, comp.a.editado_em:sub(1,16))
          end)
          span({ class = "diff-seta" }, "→")
          div({ class = "diff-versao diff-versao-b" }, function()
            span({ class = "diff-versao-label" }, "Versão B")
            span({ class = "diff-versao-data" }, comp.b.editado_em:sub(1,16))
          end)
        end)

        -- Diff do título
        h3({ class = "diff-secao-titulo" }, "Título")
        div({ class = "diff-texto" }, function()
          for _, token in ipairs(comp.diff_titulo or {}) do
            if token.tipo == "igual" then
              span(token.texto .. " ")
            elseif token.tipo == "add" then
              span({ class = "diff-add" }, token.texto .. " ")
            elseif token.tipo == "del" then
              span({ class = "diff-del" }, token.texto .. " ")
            end
          end
        end)

        -- Diff do conteúdo
        h3({ class = "diff-secao-titulo" }, "Conteúdo")
        div({ class = "diff-texto diff-conteudo" }, function()
          local tokens = comp.diff_conteudo or {}
          local max_tokens = 300  -- limita para não travar o browser
          local count = 0
          for _, token in ipairs(tokens) do
            count = count + 1
            if count > max_tokens then
              span({ class = "diff-truncado" }, "... [diff truncado para performance]")
              break
            end
            if token.tipo == "igual" then
              span(token.texto .. " ")
            elseif token.tipo == "add" then
              span({ class = "diff-add" }, token.texto .. " ")
            elseif token.tipo == "del" then
              span({ class = "diff-del" }, token.texto .. " ")
            end
          end
        end)

        -- Legenda
        div({ class = "diff-legenda" }, function()
          span({ class = "diff-add diff-legenda-item" }, "+ Adicionado")
          span({ class = "diff-del diff-legenda-item" }, "- Removido")
          span({ class = "diff-legenda-item diff-igual-ex" }, "= Igual")
        end)
      end)
    end

    -- Lista de todos os snapshots
    div({ class = "shadow-card mt-2" }, function()
      h3("📋 Todos os Snapshots")
      if self.historico and #self.historico > 0 then
        element("table", { class = "admin-table" }, function()
          thead(function()
            tr(function()
              th("ID"); th("Título (antes)"); th("Data da Edição")
            end)
          end)
          tbody(function()
            for _, h in ipairs(self.historico) do
              tr(function()
                td({ style = "font-family:monospace;font-size:.8rem" }, tostring(h.id))
                td({ class = "titulo-col" }, h.titulo_ant)
                td({ class = "data-col" }, h.editado_em:sub(1, 16))
              end)
            end
          end)
        end)
      else
        p({ class = "sem-dados" }, "Nenhuma edição registrada ainda.")
      end
    end)
  end)
end)