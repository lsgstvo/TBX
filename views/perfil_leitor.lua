-- views/perfil_leitor.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local total_conq = #(self.conquistas or {})

  -- Hero: card de identidade do leitor
  div({ class = "shadow-card perfil-hero" }, function()
    div({ class = "perfil-avatar-wrapper" }, function()
      div({ class = "perfil-avatar" }, function()
        span({ id = "perfil-avatar-display", class = "perfil-avatar-ico" }, self.leitor_avatar or "👤")
      end)
      div({ class = "perfil-info" }, function()
        div({ class = "perfil-nome-edit-container" }, function()
          input({ type = "text", id = "perfil-nome-input", class = "perfil-nome-input", 
                  value = self.leitor_nome or "Perfil", maxlength = 30,
                  onchange = "salvarNome(this.value)" })
          span({ class = "edit-icon" }, "✎")
        end)
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

    -- Seleção de Avatar
    div({ class = "avatar-selection mt-2" }, function()
      p({ class = "perfil-pref-label" }, "Escolha seu ícone:")
      div({ class = "avatar-grid" }, function()
        local icons = { "👤", "🎮", "🕹️", "👾", "🎧", "⌨️", "🖱️", "🔥", "⚡", "🎲", "🏆", "🦾", "🐉", "⚔️", "🛡️", "🏹" }
        for _, icon in ipairs(icons) do
          button({ 
            type = "button",
            class = "avatar-opt-btn" .. (icon == self.leitor_avatar and " active" or ""), 
            ["data-icon"] = icon,
            onclick = "mudarAvatar('" .. icon .. "')" 
          }, icon)
        end
      end)
    end)

    -- Categorias preferidas
    if self.categorias_pref and #self.categorias_pref > 0 then
      div({ class = "perfil-prefs mt-2" }, function()
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
          button({ type = "submit", class = "btn-limpar-perfil" }, "🗑 Limpar")
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

  raw([[
    <script>
    function mudarAvatar(icon) {
      console.log('Mudando avatar para:', icon);
      fetch('/api/perfil/avatar', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'avatar=' + encodeURIComponent(icon)
      })
      .then(r => r.json())
      .then(data => {
        if (data.success) {
          const display = document.getElementById('perfil-avatar-display');
          if (display) display.textContent = icon;
          
          const headerBtn = document.querySelector('.nav-perfil-btn');
          if (headerBtn) {
            // Preserva o nome ao mudar ícone
            const nomeStr = document.getElementById('perfil-nome-input').value;
            headerBtn.textContent = icon + ' ' + nomeStr;
          }
          
          document.querySelectorAll('.avatar-opt-btn').forEach(b => {
             const btnIcon = b.getAttribute('data-icon');
             if (btnIcon === icon) {
               b.classList.add('active');
             } else {
               b.classList.remove('active');
             }
          });
        }
      });
    }

    function salvarNome(novoNome) {
      if (!novoNome || novoNome.trim() === "") return;
      console.log('Salvando novo nome:', novoNome);
      fetch('/api/perfil/nome', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'nome=' + encodeURIComponent(novoNome)
      })
      .then(r => r.json())
      .then(data => {
        if (data.success) {
          const headerBtn = document.querySelector('.nav-perfil-btn');
          if (headerBtn) {
            const currentIcon = document.getElementById('perfil-avatar-display').textContent;
            headerBtn.textContent = currentIcon + ' ' + data.nome;
          }
          // Feedback visual opcional? (Ex: brilho no input)
          const input = document.getElementById('perfil-nome-input');
          input.style.borderColor = 'var(--accent-glow)';
          setTimeout(() => input.style.borderColor = '', 1000);
        }
      });
    }
    </script>
  ]])
end)
