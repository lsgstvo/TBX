-- views/noticias.lua
-- Listagem de notícias com busca e paginação

local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card" }, function()
    div({ class = "noticias-header" }, function()
      h2("📰 Notícias")

      -- Barra de busca
      form({ method = "GET", action = "/noticias", class = "search-form" }, function()
        input({
          type        = "text",
          name        = "q",
          value       = self.termo or "",
          placeholder = "Buscar por título ou jogo...",
          class       = "search-input",
        })
        button({ type = "submit", class = "search-btn" }, "🔍")
      end)
    end)

    -- Feedback da busca
    if self.termo and self.termo ~= "" then
      p({ class = "search-feedback" }, string.format(
        "Resultados para \"%s\" — %d encontrado(s)",
        self.termo, #(self.noticias or {})
      ))
      a({ href = "/noticias", class = "limpar-busca" }, "✕ Limpar busca")
    end

    -- Grid de notícias
    if self.noticias and #self.noticias > 0 then
      div({ class = "noticias-grid" }, function()
        for _, noticia in ipairs(self.noticias) do
          article({ class = "noticia-card" }, function()
            div({ class = "noticia-header" }, function()
              if noticia.jogo and noticia.jogo ~= "" then
                a({ href = "/jogos/" .. noticia.jogo, class = "tag" }, noticia.jogo)
              end
              span({ class = "data-noticia" }, noticia.criado_em:sub(1, 10))
            end)
            h3(function()
              a({ href = "/noticias/" .. noticia.id }, noticia.titulo)
            end)
            p({ class = "noticia-resumo" }, noticia.conteudo:sub(1, 120) .. "...")
            a({ href = "/noticias/" .. noticia.id, class = "btn-ler-mais" }, "Ler mais →")
          end)
        end
      end)
    else
      p({ class = "sem-dados" }, "Nenhuma notícia encontrada.")
    end

    -- Paginação (só aparece no modo normal, sem busca)
    if self.paginacao and self.paginacao.paginas > 1 then
      local p_atual = self.paginacao.pagina_atual
      local p_total = self.paginacao.paginas

      div({ class = "paginacao" }, function()
        -- Anterior
        if p_atual > 1 then
          a({ href = "/noticias?p=" .. (p_atual - 1), class = "pag-btn" }, "← Anterior")
        end

        -- Números de página
        for i = 1, p_total do
          local classe = i == p_atual and "pag-btn pag-ativo" or "pag-btn"
          a({ href = "/noticias?p=" .. i, class = classe }, tostring(i))
        end

        -- Próxima
        if p_atual < p_total then
          a({ href = "/noticias?p=" .. (p_atual + 1), class = "pag-btn" }, "Próxima →")
        end
      end)
    end
  end)
end)