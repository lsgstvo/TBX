-- views/conquistas.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local total_desbloqueadas = 0
  for _ in pairs(self.desbloqueadas or {}) do
    total_desbloqueadas = total_desbloqueadas + 1
  end
  local total = #(self.todas_conquistas or {})

  -- Hero
  div({ class = "shadow-card conquistas-hero" }, function()
    h2("🏅 Minhas Conquistas")
    p({ class = "conquistas-sub" },
      string.format("Você desbloqueou %d de %d conquistas possíveis.",
        total_desbloqueadas, total))
    -- Barra de progresso geral
    local pct = total > 0 and math.floor((total_desbloqueadas / total) * 100) or 0
    div({ class = "conquistas-progresso" }, function()
      div({ class = "conquistas-barra", style = "width:" .. pct .. "%" })
    end)
    span({ class = "conquistas-pct" }, pct .. "% completo")
  end)

  -- Grid de conquistas
  div({ class = "shadow-card mt-2" }, function()
    h3("Todas as Conquistas")
    div({ class = "conquistas-grid" }, function()
      for _, c in ipairs(self.todas_conquistas or {}) do
        local desbloqueada = self.desbloqueadas and self.desbloqueadas[c.tipo]
        local cls = "conquista-card" .. (desbloqueada and " conquista-ok" or " conquista-lock")

        div({ class = cls }, function()
          div({ class  = "conquista-ico",
                style  = desbloqueada
                  and ("background:rgba(" .. c.cor:gsub("#","") .. ",0.15)")
                  or  "background:rgba(100,116,139,0.1)" }, function()
            span(c.ico)
          end)
          div({ class = "conquista-info" }, function()
            p({ class = "conquista-nome" }, c.nome)
            p({ class = "conquista-desc" }, c.desc)
            if desbloqueada then
              p({ class = "conquista-data" },
                "✅ " .. desbloqueada:sub(1, 10))
            else
              p({ class = "conquista-data conquista-pendente" }, "🔒 Não desbloqueada")
            end
          end)
        end)
      end
    end)
  end)

  -- Dicas para desbloquear
  div({ class = "shadow-card mt-2" }, function()
    h3("💡 Como desbloquear mais?")
    ul({ class = "conquistas-dicas" }, function()
      li("📰 Leia mais notícias — conquistas em 5, 25 e 100 lidas")
      li("💬 Comente em uma notícia — conquista de comentarista")
      li("👍 Curta 10 notícias — conquista Like Master")
      li("🗺 Explore 5 categorias diferentes — conquista Explorador")
      li("📧 Cadastre-se na newsletter — conquista Conectado")
      li("🌙 Acesse o portal antes das 6h — conquista Madrugador")
    end)
  end)
end)