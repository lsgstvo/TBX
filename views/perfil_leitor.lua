-- views/perfil_leitor.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local total_conq = #(self.conquistas or {})

  -- Hero: card de identidade do leitor
  div({ class = "shadow-card perfil-hero" }, function()
    div({ class = "perfil-avatar-wrapper" }, function()
      -- Avatar gerado a partir do leitor_id (iniciais visuais)
      div({ class = "perfil-avatar" }, function()
        span({ class = "perfil-avatar-ico" }, "🎮")
      end)
      div({ class = "perfil-info" }, function()
        h2("Meu Perfil")
        p({ class = "perfil-id" }, "ID: " .. (self.leitor_id or ""):sub(1, 12) .. "...")
        div({ class = "perfil-stats-row" }, function()
          div({ class = "perfil-stat" }, function()
            span({ class = "perfil-stat-num" }, tostring(self.hist_total or 0))
            span({ class = "perfil-stat-lab" }, "lidas")
          end)
          div({ class = "perfil-stat" }, function()
            span({ class = "perfil-stat-num" }, tostring(total_conq))
            span({ class = "perfil-stat-lab" }, "conquistas")
          end)
          div({ class = "perfil-stat" }, function()
            span({ class = "perfil-stat-num" }, tostring(self.views_total or 0))
            span({ class = "perfil-stat-lab" }, "nesta sessão")
          end)
        end)
      end)
    end)

    -- Categorias preferidas
    if self.categorias_pref and #self.categorias_pref > 0 then
      div({ class = "perfil-prefs" }, function()
        span({ class = "perfil-pref-label" }, "Você curte: ")
        for _, c in ipairs(self.categorias_pref) do
          a({ href  = "/noticias?categoria=" .. c.categoria,
              class = "tag" }, c.categoria .. " (" .. c.total .. ")")
        end
      end)
    end
  end)

  -- Conquistas desbloqueadas
  if total_conq > 0 then
    div({ class = "shadow-card mt-2" }, function()
      div({ class = "section-header-simple" }, function()
        h3("🏅 Suas Conquistas (" .. total_conq .. ")")
        a({ href = "/conquistas", class = "btn-ver-mais" }, "Ver todas →")
      end)
      div({ class = "perfil-conquistas" }, function()
        for _, c in ipairs(self.conquistas) do
          div({ class  = "conquista-mini",
                title  = c.nome .. " — " .. c.desc,
                style  = "background:rgba(99,102,241,.08);border-color:rgba(99,102,241,.2)" }, function()
            span({ class = "conquista-mini-ico" }, c.ico)
            span({ class = "conquista-mini-nome" }, c.nome)
          end)
        end
      end)
    end)
  end

  -- Histórico de leituras
  div({ class = "shadow-card mt-2" }, function()
    div({ class = "section-header-simple" }, function()
      h3("📚 Histórico de Leituras (" .. tostring(self.hist_total or 0) .. ")")
      if (self.hist_total or 0) > 0 then
        form({ method = "POST", action = "/perfil/limpar",
               onsubmit = "return confirm('Limpar todo o histórico?')",
               style    = "display:inline" }, function()
          button({ type = "submit", class = "btn-deletar",
                   style = "font-size:.8rem;padding:.3rem .7rem" },
                 "🗑 Limpar")
        end)
      end
    end)

    if self.historico and #self.historico > 0 then
      div({ class = "noticias-grid" }, function()
        for _, n in ipairs(self.historico) do
          article({ class = "noticia-card" }, function()
            div({ class = "noticia-header" }, function()
              a({ href = "/noticias?categoria=" .. n.categoria, class = "tag" }, n.categoria)
              if n.jogo and n.jogo ~= "" then
                a({ href = "/jogos/" .. n.jogo, class = "tag tag-jogo" }, n.jogo)
              end
              span({ class = "data-noticia" }, n.lido_em:sub(1, 10))
            end)
            h3(function() a({ href = "/noticias/" .. n.id }, n.titulo) end)
            p({ class = "noticia-resumo" }, n.conteudo:sub(1, 100) .. "...")
            a({ href = "/noticias/" .. n.id, class = "btn-ler-mais" }, "Ler novamente →")
          end)
        end
      end)

      -- Paginação
      if (self.hist_total_pag or 1) > 1 then
        div({ class = "paginacao" }, function()
          if self.hist_pagina > 1 then
            a({ href  = "/perfil?pagina=" .. (self.hist_pagina - 1),
                class = "pag-btn" }, "← Anterior")
          end
          for i = 1, self.hist_total_pag do
            if i == self.hist_pagina then
              span({ class = "pag-btn pag-atual" }, tostring(i))
            else
              a({ href = "/perfil?pagina=" .. i, class = "pag-btn" }, tostring(i))
            end
          end
          if self.hist_pagina < self.hist_total_pag then
            a({ href  = "/perfil?pagina=" .. (self.hist_pagina + 1),
                class = "pag-btn" }, "Próxima →")
          end
        end)
      end
    else
      p({ class = "sem-dados" }, "Você ainda não leu nenhuma notícia neste dispositivo.")
      a({ href = "/noticias", class = "btn-ver-mais" }, "Explorar notícias →")
    end
  end)
end)