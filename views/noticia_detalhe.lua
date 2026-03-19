local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  local c = self.curtidas or { likes = 0, dislikes = 0, meu_voto = nil }

  -- Modo leitura focada: usa layout simplificado sem sidebar
  if self.modo_leitura then
    div({ class = "leitura-focada" }, function()

      -- Barra mínima de leitura
      div({ class = "leitura-topbar" }, function()
        a({ href = "/noticias/" .. self.noticia.id,
            class = "leitura-sair" }, "✕ Sair do modo leitura")
        div({ class = "leitura-progresso-wrapper" }, function()
          div({ id = "leitura-barra", class = "leitura-barra" })
        end)
        div({ class = "leitura-tempo", id = "leitura-tempo" })
      end)

      article({ class = "leitura-artigo" }, function()
        div({ class = "noticia-header" }, function()
          if self.noticia.categoria ~= "" then
            a({ href  = "/noticias?categoria=" .. self.noticia.categoria,
                class = "tag" }, self.noticia.categoria)
          end
          if self.noticia.jogo ~= "" then
            a({ href = "/jogos/" .. self.noticia.jogo,
                class = "tag tag-jogo" }, self.noticia.jogo)
          end
          span({ class = "data-noticia" }, self.noticia.criado_em:sub(1, 10))
        end)

        h1({ class = "leitura-titulo" }, self.noticia.titulo)

        if self.autor then
          div({ class = "leitura-autor" }, function()
            if self.autor.avatar_url ~= "" then
              img({ src = self.autor.avatar_url, class = "autor-avatar-mini",
                    alt = self.autor.nome })
            end
            a({ href = "/autor/" .. self.autor.id,
                class = "autor-mini-nome" }, self.autor.nome)
          end)
        end

        if self.noticia.imagem_url ~= "" then
          div({ class = "noticia-capa" }, function()
            img({ src = self.noticia.imagem_url, alt = self.noticia.titulo,
                  class = "noticia-capa-img" })
          end)
        end

        div({ class = "leitura-corpo" }, function()
          p(self.noticia.conteudo)
        end)
      end)

      script(function()
        raw([[
          // Barra de progresso de leitura
          window.addEventListener('scroll', function() {
            var el  = document.documentElement;
            var pct = (el.scrollTop / (el.scrollHeight - el.clientHeight)) * 100;
            document.getElementById('leitura-barra').style.width = pct + '%';
          });
          // Tempo estimado de leitura
          (function() {
            var corpo = document.querySelector('.leitura-corpo');
            if (!corpo) return;
            var palavras = corpo.innerText.split(/\s+/).length;
            var mins     = Math.max(1, Math.round(palavras / 200));
            document.getElementById('leitura-tempo').textContent =
              '~' + mins + ' min de leitura';
          })();
        ]])
      end)
    end)
    return  -- não renderiza o resto no modo focado
  end

  -- ── Layout normal ─────────────────────────────────────────────────────────
  div({ class = "detalhe-layout" }, function()

    div({ class = "detalhe-main" }, function()

      article({ class = "shadow-card noticia-detalhe" }, function()
        div({ class = "noticia-header" }, function()
          if self.noticia.categoria and self.noticia.categoria ~= "" then
            a({ href = "/noticias?categoria=" .. self.noticia.categoria, class = "tag" },
              self.noticia.categoria)
          end
          if self.noticia.jogo and self.noticia.jogo ~= "" then
            a({ href = "/jogos/" .. self.noticia.jogo, class = "tag tag-jogo" },
              self.noticia.jogo)
          end
          if self.noticia.destaque == 1 then
            span({ class = "badge-destaque" }, "⭐ Destaque")
          end
          span({ class = "data-noticia" }, self.noticia.criado_em:sub(1, 10))
        end)

        h2(self.noticia.titulo)

        -- Autor
        if self.autor then
          div({ class = "noticia-autor-mini", style = "margin:.4rem 0" }, function()
            if self.autor.avatar_url ~= "" then
              img({ src = self.autor.avatar_url, class = "autor-avatar-mini",
                    alt = self.autor.nome })
            end
            a({ href = "/autor/" .. self.autor.id,
                class = "autor-mini-nome" }, self.autor.nome)
          end)
        end

        -- Imagem de capa
        if self.noticia.imagem_url and self.noticia.imagem_url ~= "" then
          div({ class = "noticia-capa" }, function()
            img({ src   = self.noticia.imagem_url,
                  alt   = self.noticia.titulo,
                  class = "noticia-capa-img" })
          end)
        end

        -- Meta: views, comentários, tempo de leitura
        div({ class = "noticia-meta" }, function()
          span({ class = "meta-item" },
            "👁 " .. tostring(self.noticia.views or 0) .. " views")
          span({ class = "meta-sep" }, "·")
          span({ class = "meta-item" },
            "💬 " .. tostring(#(self.comentarios or {})) .. " comentários")
          span({ class = "meta-sep" }, "·")
          span({ class = "meta-item", id = "tempo-leitura" }, "")
          span({ class = "meta-sep" }, "·")
          -- Link modo leitura focada
          a({ href  = "/noticias/" .. self.noticia.id .. "?leitura=1",
              class = "meta-item meta-leitura",
              title = "Modo leitura focada" }, "📖 Foco")
        end)

        div({ class = "noticia-corpo", id = "noticia-corpo" }, function()
          p(self.noticia.conteudo)
        end)

        -- Tags
        if self.tags and #self.tags > 0 then
          div({ class = "noticia-tags" }, function()
            span({ class = "tags-label" }, "🏷 Tags:")
            for _, t in ipairs(self.tags) do
              a({ href  = "/tag/" .. t.nome, class = "tag tag-item" },
                "#" .. t.nome)
            end
          end)
        end

        -- Créditos / Fonte da notícia
        if self.noticia.credito_url and self.noticia.credito_url ~= "" then
          div({ class = "noticia-credito" }, function()
            span({ class = "credito-label" }, "📎 Fonte:")
            a({ href   = self.noticia.credito_url,
                target = "_blank",
                rel    = "nofollow noopener",
                class  = "credito-link" },
              self.noticia.credito_url:gsub("https?://", ""):gsub("/.*", ""))
          end)
        end

        -- ── Curtidas / Descurtidas ─────────────────────────────────────────
        div({ class = "curtidas-bar" }, function()
          -- Like
          button({ id      = "btn-like",
                   class   = "curtida-btn" .. (c.meu_voto == "like" and " ativo-like" or ""),
                   onclick = "curtir('like')",
                   title   = "Curtir" }, function()
            span({ class = "curtida-ico" }, "👍")
            span({ id = "count-like", class = "curtida-count" },
              tostring(c.likes))
          end)

          -- Barra de proporção
          div({ class = "curtida-proporcao" }, function()
            local total = c.likes + c.dislikes
            local pct   = total > 0 and math.floor((c.likes / total) * 100) or 50
            div({ class = "prop-like",
                  style = "width:" .. pct .. "%",
                  title = pct .. "% positivo" })
          end)

          -- Dislike
          button({ id      = "btn-dislike",
                   class   = "curtida-btn" .. (c.meu_voto == "dislike" and " ativo-dislike" or ""),
                   onclick = "curtir('dislike')",
                   title   = "Não curtir" }, function()
            span({ class = "curtida-ico" }, "👎")
            span({ id = "count-dislike", class = "curtida-count" },
              tostring(c.dislikes))
          end)
        end)

        div({ class = "noticia-footer" }, function()
          a({ href = "/noticias", class = "btn-voltar" }, "← Voltar")
        end)
      end)

      -- Relacionadas
      if self.relacionadas and #self.relacionadas > 0 then
        section({ class = "shadow-card mt-2" }, function()
          h3("🔗 Notícias Relacionadas")
          div({ class = "noticias-grid grid-2col" }, function()
            for _, n in ipairs(self.relacionadas) do
              article({ class = "noticia-card" }, function()
                div({ class = "noticia-header" }, function()
                  a({ href = "/noticias?categoria=" .. n.categoria, class = "tag" }, n.categoria)
                  if n.jogo and n.jogo ~= "" then
                    a({ href = "/jogos/" .. n.jogo, class = "tag tag-jogo" }, n.jogo)
                  end
                  span({ class = "data-noticia" }, n.criado_em:sub(1, 10))
                end)
                h3(function() a({ href = "/noticias/" .. n.id }, n.titulo) end)
                p({ class = "noticia-resumo" }, n.conteudo:sub(1, 100) .. "...")
                a({ href = "/noticias/" .. n.id, class = "btn-ler-mais" }, "Ler mais →")
              end)
            end
          end)
        end)
      end

if self.voce_pode_gostar and #self.voce_pode_gostar > 0 then
    section({ class = "shadow-card mt-2 voce-pode-gostar" }, function()
      h3("✨ Você Também Pode Gostar")
      div({ class = "vpg-grid" }, function()
        for _, n in ipairs(self.voce_pode_gostar) do
          a({ href = "/noticias/" .. n.id, class = "vpg-card" }, function()
            if n.imagem_url and n.imagem_url ~= "" then
              img({ src = n.imagem_url, alt = n.titulo, class = "vpg-img" })
            else
              div({ class = "vpg-placeholder" }, n.categoria:sub(1,2))
            end
            div({ class = "vpg-info" }, function()
              div({ class = "vpg-meta" }, function()
                span({ class = "tag", style = "font-size:.7rem" }, n.categoria)
                if n.tags_comuns and n.tags_comuns > 0 then
                  span({ class = "vpg-tags-badge" },
                    n.tags_comuns .. " tag" .. (n.tags_comuns > 1 and "s" or "") .. " em comum")
                end
              end)
              p({ class = "vpg-titulo" }, n.titulo)
              span({ class = "vpg-views" }, "👁 " .. tostring(n.views or 0))
            end)
          end)
        end
      end)
    end)
  end

      -- Comentários
      section({ id = "comentarios", class = "shadow-card mt-2 comentarios-section" }, function()
        h3("💬 Comentários (" .. tostring(#(self.comentarios or {})) .. ")")
        if self.erro_coment then
          div({ class = "alert alert-erro" }, self.erro_coment)
        end
        if self.flash_coment_ok then
          div({ class = "newsletter-flash coment-ok-flash" }, self.flash_coment_ok)
        end

        if self.comentarios and #self.comentarios > 0 then
          div({ class = "comentarios-lista" }, function()
            for _, com in ipairs(self.comentarios) do
              div({ class = "comentario", id = "coment-" .. com.id }, function()
                div({ class = "comentario-header" }, function()
                  span({ class = "comentario-autor" }, com.autor)
                  span({ class = "comentario-data" }, com.criado_em:sub(1, 16))
                  button({ class   = "reply-btn",
                           onclick = "abrirReply(" .. com.id .. ", '" .. com.autor:gsub("'","") .. "')" },
                         "↩ Responder")
                end)
                p({ class = "comentario-texto" }, com.conteudo)

                -- Form de reply (oculto por padrão)
                div({ id = "reply-form-" .. com.id, class = "reply-form" }, function()
                  form({ method = "POST",
                         action = "/noticias/" .. self.noticia.id .. "/comentar" }, function()
                    input({ type = "hidden", name = "parent_id", value = tostring(com.id) })
                    p({ class = "reply-hint" }, "↩ Respondendo a " .. com.autor)
                    textarea({ name = "conteudo", rows = "3", class = "reply-textarea",
                               placeholder = "Sua resposta...", maxlength = "800", required = true })
                    div({ class = "reply-actions" }, function()
                      button({ type = "submit", class = "btn-comentar" }, "Enviar resposta")
                      button({ type    = "button", class = "btn-cancelar-reply",
                               onclick = "fecharReply(" .. com.id .. ")" }, "Cancelar")
                    end)
                  end)
                end)

                -- Respostas em thread
                if com.respostas and #com.respostas > 0 then
                  div({ class = "thread-respostas" }, function()
                    for _, resp in ipairs(com.respostas) do
                      div({ class = "comentario comentario-reply" }, function()
                        div({ class = "comentario-header" }, function()
                          span({ class = "reply-ico" }, "↩")
                          span({ class = "comentario-autor" }, resp.autor)
                          span({ class = "comentario-data" }, resp.criado_em:sub(1, 16))
                        end)
                        p({ class = "comentario-texto" }, resp.conteudo)
                      end)
                    end
                  end)
                end
              end)
            end
          end)
        else
          p({ class = "sem-dados" }, "Seja o primeiro a comentar!")
        end

        div({ class = "comentario-form-wrapper" }, function()
          h4("Deixe seu comentário")
          p({ class = "field-hint", style = "margin-bottom:.6rem" },
            "Os comentários passam por moderação antes de aparecer.")
          form({ method = "POST",
                 action = "/noticias/" .. self.noticia.id .. "/comentar",
                 class  = "comentario-form", id = "form-comentario-principal" }, function()
            div({ class = "form-group" }, function()
              label({ ["for"] = "autor" }, "Nome (opcional)")
              input({ type = "text", id = "autor", name = "autor",
                      placeholder = "Seu nome ou apelido", maxlength = "60" })
            end)
            div({ class = "form-group" }, function()
              label({ ["for"] = "conteudo" }, "Comentário *")
              textarea({ id = "conteudo", name = "conteudo", rows = "4",
                         placeholder = "Escreva seu comentário...",
                         maxlength = "800", required = true })
            end)
            button({ type = "submit", class = "btn-comentar" }, "Enviar →")
          end)
        end)
      end)
    end)

    -- ── Sidebar ────────────────────────────────────────────────────────────
    aside({ class = "detalhe-sidebar" }, function()

      -- Jogos populares
      if self.jogos_populares and #self.jogos_populares > 0 then
        div({ class = "sidebar-widget shadow-card" }, function()
          h3("🏆 Jogos Populares")
          ul({ class = "sidebar-jogos" }, function()
            for i, j in ipairs(self.jogos_populares) do
              li(function()
                span({ class = "sj-pos" }, "#" .. i)
                div({ class = "sj-info" }, function()
                  a({ href = "/jogos/" .. j.nome, class = "sj-nome" }, j.nome)
                  span({ class = "sj-genero" }, j.genero)
                end)
              end)
            end
          end)
          a({ href = "/ranking", class = "sidebar-ver-mais" }, "Ver ranking →")
        end)
      end

      -- Mais lidas
      if self.mais_vistas and #self.mais_vistas > 0 then
        div({ class = "sidebar-widget shadow-card" }, function()
          h3("🔥 Mais Lidas")
          ul({ class = "sidebar-noticias" }, function()
            for _, n in ipairs(self.mais_vistas) do
              if n.id ~= self.noticia.id then
                li(function()
                  a({ href = "/noticias/" .. n.id }, function()
                    span({ class = "sn-titulo" }, n.titulo)
                    span({ class = "sn-views" }, "👁 " .. tostring(n.views or 0))
                  end)
                end)
              end
            end
          end)
        end)
      end

      -- ── Widget Clima Gamer ───────────────────────────────────────────────
      div({ class = "sidebar-widget shadow-card clima-widget" }, function()
        h3("🌡 Status dos Servidores")
        div({ id = "clima-lista", class = "clima-lista" }, function()
          p({ class = "clima-loading" }, "Verificando status...")
        end)
        p({ class = "clima-footer" }, "Atualizado via ping de popularidade")
      end)

    end)
  end) -- Fim de detalhe-layout
  
  -- Botão flutuante e Painel do Modo Leitura Avançada
  button({ class   = "leitura-float-btn",
           id      = "leitura-float-btn",
           onclick = "toggleLeituraPainel()",
           title   = "Modo Leitura Avançada" }, "📖")

  div({ id = "leitura-painel", class = "leitura-painel" }, function()
    div({ class = "leitura-painel-header" }, function()
      span("⚙️ Opções de Leitura")
      button({ class   = "leitura-painel-fechar",
               onclick = "toggleLeituraPainel()" }, "✕")
    end)
    div({ class = "leitura-painel-body" }, function()
      -- Fonte
      span({ class = "leitura-opt-label" }, "Fonte")
      div({ class = "leitura-opt-row" }, function()
        button({ class="leitura-opt-btn", ["data-opt"]="font", ["data-val"]="sans" }, "Sans")
        button({ class="leitura-opt-btn", ["data-opt"]="font", ["data-val"]="serif" }, "Serif")
        button({ class="leitura-opt-btn", ["data-opt"]="font", ["data-val"]="mono" }, "Mono")
      end)
      -- Tamanho
      span({ class = "leitura-opt-label" }, "Tamanho do Texto")
      div({ class = "leitura-opt-row" }, function()
        button({ class="leitura-opt-btn", ["data-opt"]="size", ["data-val"]="sm" }, "A-")
        button({ class="leitura-opt-btn", ["data-opt"]="size", ["data-val"]="md" }, "A")
        button({ class="leitura-opt-btn", ["data-opt"]="size", ["data-val"]="lg" }, "A+")
        button({ class="leitura-opt-btn", ["data-opt"]="size", ["data-val"]="xl" }, "A++")
      end)
      -- Espaçamento
      span({ class = "leitura-opt-label" }, "Espaçamento")
      div({ class = "leitura-opt-row" }, function()
        button({ class="leitura-opt-btn", ["data-opt"]="space", ["data-val"]="compact" }, "Compacto")
        button({ class="leitura-opt-btn", ["data-opt"]="space", ["data-val"]="normal" }, "Normal")
        button({ class="leitura-opt-btn", ["data-opt"]="space", ["data-val"]="relaxed" }, "Relaxado")
      end)
      -- Largura
      span({ class = "leitura-opt-label" }, "Largura Máxima")
      div({ class = "leitura-opt-row" }, function()
        button({ class="leitura-opt-btn", ["data-opt"]="width", ["data-val"]="narrow" }, "Estreito")
        button({ class="leitura-opt-btn", ["data-opt"]="width", ["data-val"]="standard" }, "Normal")
        button({ class="leitura-opt-btn", ["data-opt"]="width", ["data-val"]="wide" }, "Largo")
      end)
    end)
  end)

  -- Scripts
  script(function()
    raw(string.format([[
      var NOTICIA_ID = %d;
      var NOVAS_CONQUISTAS = ]] .. (self.conquistas_json or "[]") .. [[;

      // ── Thread de Comentários ─────────────────────────────────────────
      function abrirReply(id, autor) {
        fecharTodaysReplies();
        var form = document.getElementById('reply-form-' + id);
        if (form) {
            form.classList.add('reply-ativo');
            var txt = form.querySelector('textarea');
            if (txt) txt.focus();
        }
      }
      function fecharReply(id) {
        var form = document.getElementById('reply-form-' + id);
        if (form) form.classList.remove('reply-ativo');
      }
      function fecharTodaysReplies() {
        document.querySelectorAll('.reply-form').forEach(function(f) {
           f.classList.remove('reply-ativo');
        });
      }

      // ── Modo Leitura Avançada ─────────────────────────────────────────
      var cfgLeitura = JSON.parse(localStorage.getItem('modo_leitura_av') || '{}');
      
      function aplicarConfigLeitura(cfg) {
        var corpo = document.getElementById('noticia-corpo');
        if (!corpo) return;
        
        // Remove classes anteriores
        corpo.classList.remove('font-sans','font-serif','font-mono','size-sm','size-md','size-lg','size-xl','space-compact','space-normal','space-relaxed','width-narrow','width-standard','width-wide');
        
        if (cfg.font)  corpo.classList.add('font-' + cfg.font);
        if (cfg.size)  corpo.classList.add('size-' + cfg.size);
        if (cfg.space) corpo.classList.add('space-' + cfg.space);
        if (cfg.width) corpo.classList.add('width-' + cfg.width);
        
        // Atualiza botões ativos no painel
        document.querySelectorAll('.leitura-opt-btn').forEach(function(btn) {
           var opt = btn.dataset.opt;
           var val = btn.dataset.val;
           btn.classList.toggle('leitura-opt-ativo', cfg[opt] === val);
        });
        localStorage.setItem('modo_leitura_av', JSON.stringify(cfg));
      }

      function toggleLeituraPainel() {
        var p = document.getElementById('leitura-painel');
        if (p) p.classList.toggle('leitura-painel-visivel');
      }

      document.querySelectorAll('.leitura-opt-btn').forEach(function(btn) {
        btn.onclick = function() {
          cfgLeitura[this.dataset.opt] = this.dataset.val;
          aplicarConfigLeitura(cfgLeitura);
        };
      });

      // Inicializa
      if (!cfgLeitura.size) { // Defaults
        cfgLeitura = { font:'sans', size:'md', space:'normal', width:'standard' };
      }
      aplicarConfigLeitura(cfgLeitura);

      // ── Tempo de leitura ─────────────────────────────────────────────
      (function() {
        var corpo = document.getElementById('noticia-corpo');
        if (!corpo) return;
        var palavras = corpo.innerText.split(/\s+/).length;
        var mins     = Math.max(1, Math.round(palavras / 200));
        var el = document.getElementById('tempo-leitura');
        if (el) el.textContent = '~' + mins + ' min';
      })();

      // ── Curtidas ─────────────────────────────────────────────────────
      function curtir(tipo) {
        fetch('/api/curtir/' + NOTICIA_ID, {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: 'tipo=' + tipo
        })
        .then(function(r) { return r.json(); })
        .then(function(data) {
          if (data.status !== 'ok') return;
          document.getElementById('count-like').textContent    = data.likes;
          document.getElementById('count-dislike').textContent = data.dislikes;
          var btnLike    = document.getElementById('btn-like');
          var btnDislike = document.getElementById('btn-dislike');
          btnLike.classList.toggle('ativo-like',       data.meu_voto === 'like');
          btnDislike.classList.toggle('ativo-dislike', data.meu_voto === 'dislike');
          // Atualiza barra de proporção
          var total = data.likes + data.dislikes;
          var pct   = total > 0 ? Math.round((data.likes / total) * 100) : 50;
          var prop  = document.querySelector('.prop-like');
          if (prop) prop.style.width = pct + '%%';
        })
        .catch(function() {});
      }

      // ── Enquete ───────────────────────────────────────────────────────
      function votarEnquete(enqueteId, opcaoId) {
        fetch('/api/enquete/' + enqueteId + '/votar', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: 'opcao_id=' + opcaoId
        })
        .then(function(r){ return r.json(); })
        .then(function(data){
          if (data.status === 'ja_votou') {
            alert('Voc\u00ea j\u00e1 votou nesta enquete!');
            return;
          }
          if (data.status !== 'ok' || !data.enquete) return;
          var enq   = data.enquete;
          var total = enq.total_votos || 0;
          (enq.opcoes || []).forEach(function(op) {
            var pct = total > 0 ? Math.round((op.votos / total) * 100) : 0;
            var btn = document.querySelector('[data-id="' + op.id + '"]');
            if (!btn) return;
            var fill  = btn.querySelector('.enquete-barra-fill');
            var label = btn.querySelector('.enquete-opcao-pct');
            if (fill)  fill.style.width = pct + '%%';
            if (label) label.textContent = pct + '%% (' + op.votos + ')';
            btn.disabled = true;
          });
          var totalEl = document.getElementById('enquete-total');
          if (totalEl) totalEl.textContent = total + ' voto' + (total === 1 ? '' : 's');
        })
        .catch(function(){});
      }

      // ── Toasts de conquistas novas ───────────────────────────────────
      (function() {
        if (!NOVAS_CONQUISTAS || NOVAS_CONQUISTAS.length === 0) return;
        var delay = 800;
        NOVAS_CONQUISTAS.forEach(function(c) {
          setTimeout(function() {
            var toast = document.createElement('div');
            toast.className = 'conquista-toast';
            toast.innerHTML =
              '<span class="toast-ico">' + c.ico + '</span>' +
              '<div class="toast-info">' +
                '<div class="toast-titulo">&#127885; Conquista desbloqueada!</div>' +
                '<div style="font-weight:700;font-size:.9rem;color:' + c.cor + '">' + c.nome + '</div>' +
                '<div class="toast-desc">' + c.desc + '</div>' +
              '</div>';
            document.body.appendChild(toast);
            setTimeout(function() {
              toast.style.opacity = '0';
              toast.style.transition = 'opacity .5s';
              setTimeout(function() { document.body.removeChild(toast); }, 500);
            }, 4000);
          }, delay);
          delay += 1200;
        });
      })();

      // ── Widget Clima Gamer ────────────────────────────────────────────
      // Simula status de servidores com base em horário/dia (sem API externa)
      (function() {
        var jogos = [
          { nome: "Valorant",          cor: "#f43f5e" },
          { nome: "CS2",               cor: "#f59e0b" },
          { nome: "League of Legends", cor: "#6366f1" },
          { nome: "Fortnite",          cor: "#22c55e" },
          { nome: "Minecraft",         cor: "#84cc16" },
        ];

        var hora = new Date().getHours();
        // Pico de jogadores: 18h-23h = lotado
        var base = (hora >= 18 && hora <= 23) ? 80
                 : (hora >= 12 && hora <= 17) ? 60
                 : (hora >= 8  && hora <= 11) ? 40 : 25;

        var lista = document.getElementById('clima-lista');
        if (!lista) return;

        var html = '';
        jogos.forEach(function(j) {
          var variacao = Math.floor(Math.random() * 20) - 10;
          var carga    = Math.min(100, Math.max(5, base + variacao));
          var status   = carga >= 85 ? 'Lotado'
                       : carga >= 60 ? 'Cheio'
                       : carga >= 35 ? 'Normal' : 'Tranquilo';
          var cor      = carga >= 85 ? '#f43f5e'
                       : carga >= 60 ? '#f59e0b'
                       : carga >= 35 ? '#4ade80' : '#94a3b8';
          html += '<div class="clima-item">' +
            '<span class="clima-nome">' + j.nome + '</span>' +
            '<div class="clima-barra-wrapper">' +
              '<div class="clima-barra" style="width:' + carga + '%%;background:' + cor + '"></div>' +
            '</div>' +
            '<span class="clima-status" style="color:' + cor + '">' + status + '</span>' +
          '</div>';
        });
        lista.innerHTML = html;
      })();
    ]], self.noticia.id))
  end)
end)