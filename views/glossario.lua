local Widget = require("lapis.html").Widget

return Widget:extend(function(self)

  -- Hero + busca
  div({ class = "shadow-card glossario-hero" }, function()
    h2("📖 Glossário Gamer")
    p({ class = "glossario-desc" },
      "Dicionário de termos, jargões e siglas do universo dos games.")
    form({ method = "GET", action = "/glossario", class = "glossario-busca-form" }, function()
      div({ class = "glossario-busca-wrapper" }, function()
        input({ type        = "text",
                name        = "q",
                value       = self.busca or "",
                placeholder = "Buscar termo... ex: DPS, Nerf, Gank",
                class       = "glossario-busca-input",
                autocomplete = "off" })
        button({ type = "submit", class = "glossario-busca-btn" }, "🔍")
        if self.busca and self.busca ~= "" then
          a({ href = "/glossario", class = "glossario-limpar" }, "✕ Limpar")
        end
      end)
    end)
  end)

  -- Índice alfabético
  div({ class = "shadow-card mt-2 glossario-indice-card" }, function()
    div({ class = "glossario-indice" }, function()
      local todas_letras = "ABCDEFGHIJKLMNOPQRSTUVWXYZ#"
      local disponiveis = {}
      for _, l in ipairs(self.letras_disponiveis or {}) do
        disponiveis[l] = true
      end
      for i = 1, #todas_letras do
        local l = todas_letras:sub(i, i)
        local ativa = (self.letra == l)
        if disponiveis[l] then
          a({ href  = "/glossario?letra=" .. l,
              class = "indice-letra" .. (ativa and " indice-ativa" or "") }, l)
        else
          span({ class = "indice-letra indice-vazia" }, l)
        end
      end
      a({ href  = "/glossario",
          class = "indice-letra" .. (not self.letra and not self.busca and " indice-ativa" or "") },
        "Todos")
    end)
  end)

  -- Resultado
  if self.termos and #self.termos > 0 then
    local letra_atual = ""
    div({ class = "shadow-card mt-2" }, function()
      -- Título do filtro ativo
      if self.busca and self.busca ~= "" then
        p({ class = "glossario-filtro-label" },
          "🔍 " .. #self.termos .. ' resultado(s) para "' .. self.busca .. '"')
      elseif self.letra then
        p({ class = "glossario-filtro-label" },
          "Mostrando termos com " .. self.letra)
      end

      div({ class = "glossario-lista" }, function()
        for _, t in ipairs(self.termos) do
          -- Separador de letra
          local l = t.termo:upper():sub(1, 1)
          if l ~= letra_atual then
            letra_atual = l
            div({ class = "glossario-letra-sep" }, function()
              span(l)
            end)
          end

          div({ class = "glossario-item", id = "termo-" .. t.id }, function()
            div({ class = "glossario-item-header" }, function()
              h3({ class = "glossario-termo" }, t.termo)
              span({ class = "tag glossario-cat" }, t.categoria)
            end)
            p({ class = "glossario-definicao" }, t.definicao)
          end)
        end
      end)
    end)
  elseif self.busca and self.busca ~= "" then
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" },
        'Nenhum termo encontrado para "' .. self.busca .. '". ')
      a({ href = "/glossario", class = "btn-ver-mais" }, "Ver todos os termos →")
    end)
  else
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" }, "Nenhum termo cadastrado ainda.")
      p({ style = "font-size:.85rem;color:var(--text-muted);margin-top:.5rem" },
        "O glossário pode ser gerenciado em Admin → Glossário.")
    end)
  end
end)