-- views/busca_avancada.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local f = self.filtros or {}

  div({ class = "shadow-card" }, function()
    h2("🔍 Busca Avançada")

    form({ method = "GET", action = "/busca", class = "busca-av-form" }, function()

      -- Linha 1: termo + ordem
      div({ class = "form-row" }, function()
        div({ class = "form-group form-grow" }, function()
          label({ ["for"] = "q" }, "Termo")
          input({ type = "text", id = "q", name = "q",
                  value = f.termo or "",
                  placeholder = "Palavra-chave no título ou conteúdo..." })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "ordem" }, "Ordenar por")
          element("select", { id = "ordem", name = "ordem" }, function()
            local ordens = {
              { "recente", "Mais recente" },
              { "antigo",  "Mais antigo"  },
              { "views",   "Mais vistas"  },
              { "titulo",  "Título (A-Z)" },
            }
            for _, o in ipairs(ordens) do
              local attrs = { value = o[1] }
              if (f.ordem or "recente") == o[1] then attrs.selected = true end
              option(attrs, o[2])
            end
          end)
        end)
      end)

      -- Linha 2: categoria + jogo + autor
      div({ class = "form-row" }, function()
        div({ class = "form-group" }, function()
          label({ ["for"] = "categoria" }, "Categoria")
          element("select", { id = "categoria", name = "categoria" }, function()
            option({ value = "" }, "Todas")
            for _, c in ipairs(self.categorias or {}) do
              local attrs = { value = c.nome }
              if f.categoria == c.nome then attrs.selected = true end
              option(attrs, c.nome)
            end
          end)
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "jogo" }, "Jogo")
          element("select", { id = "jogo", name = "jogo" }, function()
            option({ value = "" }, "Todos")
            for _, j in ipairs(self.jogos or {}) do
              local attrs = { value = j.nome }
              if f.jogo == j.nome then attrs.selected = true end
              option(attrs, j.nome)
            end
          end)
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "autor" }, "Autor")
          element("select", { id = "autor", name = "autor" }, function()
            option({ value = "" }, "Todos")
            for _, a in ipairs(self.autores or {}) do
              local attrs = { value = tostring(a.id) }
              if f.autor_id == tostring(a.id) then attrs.selected = true end
              option(attrs, a.nome)
            end
          end)
        end)
      end)

      -- Linha 3: datas + destaque
      div({ class = "form-row" }, function()
        div({ class = "form-group" }, function()
          label({ ["for"] = "data_de" }, "De")
          input({ type = "date", id = "data_de", name = "data_de",
                  value = f.data_de or "" })
        end)
        div({ class = "form-group" }, function()
          label({ ["for"] = "data_ate" }, "Até")
          input({ type = "date", id = "data_ate", name = "data_ate",
                  value = f.data_ate or "" })
        end)
        div({ class = "form-group", style = "justify-content:flex-end" }, function()
          div({ class = "form-check", style = "margin-top:1.6rem" }, function()
            local attrs = { type = "checkbox", id = "destaque",
                            name = "destaque", value = "1" }
            if f.destaque == "1" then attrs.checked = true end
            input(attrs)
            label({ ["for"] = "destaque" }, "⭐ Apenas destaques")
          end)
        end)
      end)

      div({ class = "form-actions" }, function()
        button({ type = "submit", class = "btn-salvar" }, "🔍 Buscar")
        a({ href = "/busca", class = "btn-cancelar" }, "Limpar filtros")
      end)
    end)
  end)

  -- Resultados
  if self.buscou then
    div({ class = "shadow-card mt-2" }, function()
      div({ class = "noticias-header" }, function()
        h3("Resultados — " .. tostring(#(self.noticias or {})) .. " encontrado(s)")
      end)

      if self.noticias and #self.noticias > 0 then
        div({ class = "noticias-grid" }, function()
          for _, n in ipairs(self.noticias) do
            article({ class = "noticia-card" .. (n.destaque == 1 and " card-destaque" or "") }, function()
              div({ class = "noticia-header" }, function()
                a({ href = "/noticias?categoria=" .. n.categoria, class = "tag" }, n.categoria)
                if n.jogo and n.jogo ~= "" then
                  a({ href = "/jogos/" .. n.jogo, class = "tag tag-jogo" }, n.jogo)
                end
                if n.destaque == 1 then span({ class = "badge-destaque" }, "⭐") end
                span({ class = "data-noticia" }, n.criado_em:sub(1, 10))
              end)
              -- Autor
              if n.autor_nome and n.autor_nome ~= "" then
                div({ class = "noticia-autor-mini" }, function()
                  if n.autor_avatar and n.autor_avatar ~= "" then
                    img({ src = n.autor_avatar, class = "autor-avatar-mini", alt = n.autor_nome })
                  end
                  a({ href = "/autor/" .. (n.autor_id or ""), class = "autor-mini-nome" }, n.autor_nome)
                end)
              end
              h3(function() a({ href = "/noticias/" .. n.id }, n.titulo) end)
              p({ class = "noticia-resumo" }, n.conteudo:sub(1, 120) .. "...")
              a({ href = "/noticias/" .. n.id, class = "btn-ler-mais" }, "Ler mais →")
            end)
          end
        end)
      else
        p({ class = "sem-dados" }, "Nenhuma notícia encontrada com esses filtros.")
      end
    end)
  end
end)