local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "shadow-card galeria-hero" }, function()
    h2("🖼 Galeria de Jogos")
    p({ class = "galeria-desc" }, "Imagens, artes e screenshots dos jogos do ranking.")
  end)

  -- Filtro por jogo
  div({ class = "shadow-card mt-2 galeria-filtro-card" }, function()
    div({ class = "galeria-filtros" }, function()
      a({ href  = "/galeria",
          class = "galeria-filtro-btn" .. (not self.jogo_filtro or self.jogo_filtro == "" and " filtro-ativo" or "") },
        "Todos")
      for _, j in ipairs(self.jogos or {}) do
        a({ href  = "/galeria?jogo=" .. j.nome:gsub(" ", "%%20"),
            class = "galeria-filtro-btn" .. (self.jogo_filtro == j.nome and " filtro-ativo" or "") },
          j.nome)
      end
    end)
  end)

  -- Grid de imagens
  if self.imagens and #self.imagens > 0 then
    div({ class = "shadow-card mt-2" }, function()
      if self.jogo_atual then
        h3(self.jogo_atual.nome .. " — " .. #self.imagens .. " imagem(ns)")
      else
        h3(#self.imagens .. " imagem(ns) no total")
      end
      div({ class = "galeria-grid", id = "galeria-grid" }, function()
        for _, img_item in ipairs(self.imagens) do
          div({ class = "galeria-item",
                onclick = "abrirLightbox('" .. img_item.url .. "', '" ..
                          (img_item.legenda or ""):gsub("'","") .. "')" }, function()
            img({ src     = img_item.url,
                  alt     = img_item.legenda ~= "" and img_item.legenda or img_item.jogo_nome,
                  class   = "galeria-img",
                  loading = "lazy" })
            if img_item.legenda ~= "" then
              div({ class = "galeria-legenda" }, img_item.legenda)
            end
            if img_item.jogo_nome then
              div({ class = "galeria-jogo-badge" }, function()
                a({ href  = "/jogos/" .. img_item.jogo_nome,
                    class = "tag tag-jogo",
                    onclick = "event.stopPropagation()" },
                  img_item.jogo_nome)
              end)
            end
          end)
        end
      end)
    end)
  else
    div({ class = "shadow-card mt-2" }, function()
      p({ class = "sem-dados" }, "Nenhuma imagem cadastrada ainda.")
      p({ style = "font-size:.85rem;color:var(--text-muted);margin-top:.5rem" },
        "Imagens podem ser adicionadas em Admin → Galeria.")
    end)
  end

  -- Lightbox
  div({ id = "lightbox", class = "lightbox", onclick = "fecharLightbox()" }, function()
    div({ class = "lightbox-inner", onclick = "event.stopPropagation()" }, function()
      button({ class = "lightbox-fechar", onclick = "fecharLightbox()" }, "✕")
      img({ id = "lightbox-img", src = "", alt = "", class = "lightbox-imagem" })
      p({ id = "lightbox-legenda", class = "lightbox-legenda" })
    end)
  end)

  script(function()
    raw([[
      function abrirLightbox(url, legenda) {
        var lb  = document.getElementById('lightbox');
        var img = document.getElementById('lightbox-img');
        var leg = document.getElementById('lightbox-legenda');
        if (!lb || !img) return;
        img.src = url;
        leg.textContent = legenda || '';
        lb.classList.add('lightbox-visivel');
        document.body.style.overflow = 'hidden';
      }
      function fecharLightbox() {
        var lb = document.getElementById('lightbox');
        if (lb) lb.classList.remove('lightbox-visivel');
        document.body.style.overflow = '';
      }
      document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') fecharLightbox();
      });
    ]])
  end)
end)