local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local c = self.cronica

  -- Modo leitura focada
  if self.params and self.params.leitura == "1" then
    div({ class = "leitura-focada" }, function()
      div({ class = "leitura-topbar" }, function()
        a({ href = "/cronicas/" .. c.id, class = "leitura-sair" },
          "✕ Sair do modo leitura")
        div({ class = "leitura-progresso-wrapper" }, function()
          div({ id = "leitura-barra", class = "leitura-barra" })
        end)
        span({ class = "leitura-tempo" },
          "⏱ " .. tostring(self.tempo_leitura or 1) .. " min de leitura")
      end)
      article({ class = "leitura-artigo" }, function()
        span({ class = "cronica-tipo-badge" }, "✍️ Crônica & Editorial")
        h1({ class = "leitura-titulo" }, c.titulo)
        if c.subtitulo and c.subtitulo ~= "" then
          p({ class = "cronica-artigo-subtitulo" }, c.subtitulo)
        end
        div({ class = "leitura-corpo cronica-artigo-corpo" }, function()
          local paragrafos = {}
          for par in (c.conteudo .. "\n\n"):gmatch("(.-)%s*\n%s*\n") do
            par = par:match("^%s*(.-)%s*$")
            if par ~= "" then table.insert(paragrafos, par) end
          end
          if #paragrafos == 0 then
            p(c.conteudo)
          else
            for _, par in ipairs(paragrafos) do
              p({ class = "cronica-par" }, par)
            end
          end
        end)
      end)
      script(function()
        raw([[
          window.addEventListener('scroll', function() {
            var el  = document.documentElement;
            var pct = (el.scrollTop / (el.scrollHeight - el.clientHeight)) * 100;
            document.getElementById('leitura-barra').style.width = pct + '%';
          });
        ]])
      end)
    end)
    return
  end

  -- Layout normal
  article({ class = "cronica-artigo shadow-card" }, function()
    div({ class = "cronica-artigo-header" }, function()
      span({ class = "cronica-tipo-badge" }, "✍️ Crônica & Editorial")
      if c.destaque == 1 then
        span({ class = "badge-destaque" }, "⭐ Destaque")
      end
    end)

    h1({ class = "cronica-artigo-titulo" }, c.titulo)

    if c.subtitulo and c.subtitulo ~= "" then
      p({ class = "cronica-artigo-subtitulo" }, c.subtitulo)
    end

    div({ class = "cronica-artigo-meta" }, function()
      if c.autor_nome and c.autor_nome ~= "" then
        div({ class = "noticia-autor-mini" }, function()
          if c.autor_avatar and c.autor_avatar ~= "" then
            img({ src = c.autor_avatar, alt = c.autor_nome,
                  class = "autor-avatar-mini" })
          end
          a({ href = "/autor/" .. (c.autor_id or ""),
              class = "autor-mini-nome" }, c.autor_nome)
        end)
        span({ class = "meta-sep" }, "·")
      end
      span({ class = "meta-item" }, c.criado_em:sub(1, 10))
      span({ class = "meta-sep" }, "·")
      span({ class = "meta-item tempo-leitura-badge" },
        "⏱ " .. tostring(self.tempo_leitura or 1) .. " min de leitura")
      span({ class = "meta-sep" }, "·")
      span({ class = "meta-item" },
        "👁 " .. tostring(c.views or 0) .. " leituras")
      span({ class = "meta-sep" }, "·")
      a({ href  = "/cronicas/" .. c.id .. "?leitura=1",
          class = "meta-item meta-leitura", title = "Modo leitura" }, "📖 Foco")
    end)

    if c.imagem_url and c.imagem_url ~= "" then
      div({ class = "cronica-artigo-capa" }, function()
        img({ src = c.imagem_url, alt = c.titulo, class = "noticia-capa-img" })
      end)
    end

    div({ class = "cronica-artigo-corpo" }, function()
      local paragrafos = {}
      for par in (c.conteudo .. "\n\n"):gmatch("(.-)%s*\n%s*\n") do
        par = par:match("^%s*(.-)%s*$")
        if par ~= "" then table.insert(paragrafos, par) end
      end
      if #paragrafos == 0 then
        p(c.conteudo)
      else
        for _, par in ipairs(paragrafos) do
          p({ class = "cronica-par" }, par)
        end
      end
    end)

    if c.tags_str and c.tags_str ~= "" then
      div({ class = "noticia-tags" }, function()
        span({ class = "tags-label" }, "🏷 Tags:")
        for tag in c.tags_str:gmatch("[^,]+") do
          local t = tag:match("^%s*(.-)%s*$")
          if t ~= "" then
            a({ href = "/tag/" .. t, class = "tag tag-item" }, "#" .. t)
          end
        end
      end)
    end

    div({ class = "noticia-footer" }, function()
      a({ href = "/cronicas", class = "btn-voltar" }, "← Voltar para Crônicas")
    end)
  end)

  -- Barra de progresso
  script(function()
    raw([[
      (function() {
        var barra = document.createElement('div');
        barra.style.cssText =
          'position:fixed;top:0;left:0;height:3px;background:var(--primary-color);width:0;z-index:999;transition:width .1s';
        document.body.appendChild(barra);
        window.addEventListener('scroll', function() {
          var el  = document.documentElement;
          var pct = el.scrollHeight > el.clientHeight
            ? (el.scrollTop / (el.scrollHeight - el.clientHeight)) * 100 : 0;
          barra.style.width = pct + '%';
        });
      })();
    ]])
  end)
end)