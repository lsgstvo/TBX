-- views/noticias.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card" }, function()

    -- Cabeçalho + busca
    div({ class = "noticias-header" }, function()
      h2("📰 Notícias")
      form({ method = "GET", action = "/noticias", class = "busca-form" }, function()
        input({ type = "text", name = "q", value = self.termo or "",
                placeholder = "Buscar...", class = "busca-input" })
        button({ type = "submit", class = "busca-btn" }, "🔍")
      end)
    end)

    -- Filtros de categoria
    if self.categorias and #self.categorias > 0 then
      div({ class = "categoria-filtros" }, function()
        local ativa = self.categoria_ativa or self.categoria or ""
        a({ href  = "/noticias",
            class = "filtro-btn" .. (ativa == "" and " filtro-ativo" or "") },
          "Todas")
        for _, cat in ipairs(self.categorias) do
          a({ href  = "/noticias?categoria=" .. cat.nome,
              class = "filtro-btn" .. (ativa == cat.nome and " filtro-ativo" or "") },
            cat.nome)
        end
      end)
    end

    -- Resultado de busca
    if self.modo_busca then
      p({ class = "busca-resultado" }, string.format(
        'Resultados para "%s" — %d encontrado(s)', self.termo or "", #self.noticias
      ))
      if #self.noticias == 0 then
        div({ class = "busca-vazia" }, function()
          p("Nenhuma notícia encontrada.")
          a({ href = "/noticias", class = "btn-ver-mais" }, "← Ver todas")
        end)
      end
    end

    -- Grid de cards
    if self.noticias and #self.noticias > 0 then
      div({ class = "noticias-grid" }, function()
        for _, n in ipairs(self.noticias) do
          article({ class = "noticia-card" .. (n.destaque == 1 and " card-destaque" or "") }, function()
            div({ class = "noticia-header" }, function()
              a({ href = "/noticias?categoria=" .. n.categoria, class = "tag" }, n.categoria)
              if n.jogo and n.jogo ~= "" then
                a({ href = "/jogos/" .. n.jogo, class = "tag tag-jogo" }, n.jogo)
              end
              if n.destaque == 1 then
                span({ class = "badge-destaque" }, "⭐ Destaque")
              end
              span({ class = "data-noticia" }, n.criado_em:sub(1, 10))
            end)
            h3(function()
              a({ href = "/noticias/" .. n.id }, n.titulo)
            end)
            p({ class = "noticia-resumo" }, n.conteudo:sub(1, 120) .. "...")
            a({ href = "/noticias/" .. n.id, class = "btn-ler-mais" }, "Ler mais →")
          end)
        end
      end)
    end

    -- Paginação
    if not self.modo_busca and self.total_paginas and self.total_paginas > 1 then
      local cat_param = (self.categoria_ativa and self.categoria_ativa ~= "")
                        and ("&categoria=" .. self.categoria_ativa) or ""
      div({ class = "paginacao" }, function()
        if self.pagina > 1 then
          a({ href = "/noticias?pagina=" .. (self.pagina - 1) .. cat_param, class = "pag-btn" }, "← Anterior")
        end
        for i = 1, self.total_paginas do
          if i == self.pagina then
            span({ class = "pag-btn pag-atual" }, tostring(i))
          else
            a({ href = "/noticias?pagina=" .. i .. cat_param, class = "pag-btn" }, tostring(i))
          end
        end
        if self.pagina < self.total_paginas then
          a({ href = "/noticias?pagina=" .. (self.pagina + 1) .. cat_param, class = "pag-btn" }, "Próxima →")
        end
      end)
    end

  end)
end)