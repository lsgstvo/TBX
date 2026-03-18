local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  html_5(function()
    head(function()
      meta({ charset = "UTF-8" })
      meta({ name = "viewport", content = "width=device-width, initial-scale=1.0" })
      local titulo_pag = self.og_titulo
        and (self.og_titulo .. " — Portal Gamer") or "Portal Gamer"
      title(titulo_pag)
      local og_titulo = self.og_titulo     or "Portal Gamer"
      local og_desc   = self.og_descricao
        or "Fique por dentro das últimas notícias, rankings e atualizações do mundo dos games."
      local og_url    = self.og_url    or "http://localhost:8080"
      local og_img    = self.og_imagem or "http://localhost:8080/static/og-default.png"
      local og_tipo   = self.og_tipo   or "website"
      meta({ name = "description", content = og_desc })
      meta({ name = "robots",      content = "index, follow" })
      meta({ property = "og:type",        content = og_tipo })
      meta({ property = "og:site_name",   content = "Portal Gamer" })
      meta({ property = "og:title",       content = og_titulo })
      meta({ property = "og:description", content = og_desc })
      meta({ property = "og:url",         content = og_url })
      meta({ property = "og:image",       content = og_img })
      meta({ property = "og:locale",      content = "pt_BR" })
      meta({ name = "twitter:card",        content = "summary_large_image" })
      meta({ name = "twitter:title",       content = og_titulo })
      meta({ name = "twitter:description", content = og_desc })
      meta({ name = "twitter:image",       content = og_img })
      link({ rel = "canonical", href = og_url })
      script(function()
        raw([[
          (function() {
            var tema = localStorage.getItem('tema') || 'dark';
            document.documentElement.setAttribute('data-tema', tema);
          })();
        ]])
      end)
      link({ rel = "stylesheet", href = "/static/style.css?v=4" })
      link({ rel = "alternate", type = "application/rss+xml",
             title = "Portal Gamer RSS", href = "/rss" })
      -- PWA
      link({ rel = "manifest", href = "/manifest.json" })
      meta({ name = "theme-color", content = "#6366f1" })
      meta({ name = "mobile-web-app-capable", content = "yes" })
      meta({ name = "apple-mobile-web-app-capable", content = "yes" })
      meta({ name = "apple-mobile-web-app-status-bar-style", content = "black-translucent" })
      meta({ name = "apple-mobile-web-app-title", content = "Portal Gamer" })
      link({ href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap",
             rel  = "stylesheet" })
    end)

    body(function()
      header({ class = "site-header" }, function()
        div({ class = "container header-inner" }, function()
          button({ id = "drawer-toggle", class = "drawer-toggle-btn", 
                   title = "Menu", onclick = "toggleDrawer()" }, "☰")

          a({ href = "/", class = "site-brand" }, function()
            img({ src = "/static/icon-192.png", class = "brand-logo", alt = "Logo" })
            span("Portal Gamer")
          end)
          
          div({ class = "header-actions" }, function()
            -- Busca sempre visível
            div({ class = "header-busca visible", id = "header-busca" }, function()
              button({ id = "voice-btn", class = "search-toggle-btn voice-btn",
                       title = "Busca por voz", onclick = "iniciarBuscaVoz()" }, "🎤")
              input({ type = "text", id = "busca-global", class = "busca-global-input",
                      placeholder = "Buscar...", autocomplete = "off" })
              div({ id = "busca-resultados", class = "busca-resultados" })
            end)

            if self.leitor_nivel_info then
              local niv = self.leitor_nivel_info
              div({ class = "header-xp-badge", title = string.format("Nível %d: %s (%d/%d XP)", 
                    niv.nivel.nivel, niv.nivel.nome, niv.xp, niv.proximo and niv.proximo.xp_min or niv.xp) }, function()
                span({ class = "xp-ico" }, niv.nivel.ico)
                span({ class = "xp-num" }, tostring(niv.nivel.nivel))
                div({ class = "xp-progress-mini" }, function()
                  div({ class = "xp-bar-mini", style = "width:" .. niv.pct_proximo .. "%" })
                end)
              end)
            end

            a({ href = "/notificacoes", class = "header-icon-btn", title = "Notificações" }, function()
              text("🔔")
              if self.notificacoes_count and self.notificacoes_count > 0 then
                span({ id = "notificacoes-badge", class = "header-badge" }, tostring(self.notificacoes_count))
              end
            end)
            
            button({ id = "tema-toggle", class = "tema-btn",
                     title = "Alternar tema", onclick = "toggleTema()" }, "☀️")
          end)
        end)
      end)

      -- Side Drawer & Overlay
      div({ id = "drawer-overlay", class = "drawer-overlay", onclick = "toggleDrawer()" })
      div({ id = "side-drawer", class = "side-drawer" }, function()
        div({ class = "drawer-header" }, function()
          span({ class = "drawer-title" }, "Navegação")
          button({ class = "drawer-close", onclick = "toggleDrawer()" }, "✕")
        end)
        
        div({ class = "drawer-profile" }, function()
          a({ href = "/perfil", class = "drawer-perfil-card" }, function()
            span({ class = "drawer-avatar" }, self.leitor_icon or "👤")
            div({ class = "drawer-user-info" }, function()
              span({ class = "drawer-username" }, self.leitor_nome or "Visitante")
              span({ class = "drawer-view-profile" }, "Ver perfil →")
            end)
          end)
        end)

        nav({ class = "drawer-nav" }, function()
          a({ href = "/" },         "🏠 Início")
          a({ href = "/noticias" }, "📰 Notícias")
          a({ href = "/trending" }, "🔥 Trending")
          a({ href = "/ranking" },  "🏆 Ranking")
          a({ href = "/sobre" },    "ℹ️ Sobre")
          a({ href = "/feed" },      "⚡ Feed")
          a({ href = "/glossario" }, "📖 Glossário")
          a({ href = "/admin" },    "⚙️ Admin")
          -- PWA Install Button
          button({ id = "pwa-install-btn", onclick = "instalarPWA()", style = "margin-top: 1.5rem; display: none;" }, function()
            span("📲 Instalar App")
          end)
        end)
      end)

      -- Mensagem de newsletter (flash — lido e zerado no handler do app.lua)
      if self.flash_newsletter_msg then
        div({ class = "container" }, function()
          div({ class = "newsletter-flash" }, self.flash_newsletter_msg)
        end)
      end

      -- Mensagem de comentário ok (flash — lido e zerado no handler do app.lua)
      if self.flash_coment_ok then
        div({ class = "container" }, function()
          div({ class = "newsletter-flash coment-ok-flash" }, self.flash_coment_ok)
        end)
      end

      main({ class = "container content-area" }, function()
        self:content_for("inner")
      end)

      -- Footer com widget de newsletter
      footer({ class = "site-footer" }, function()
        div({ class = "container" }, function()
          -- Widget newsletter
          div({ class = "footer-newsletter" }, function()
            div({ class = "newsletter-texto" }, function()
              span({ class = "newsletter-titulo" }, "📧 Fique por dentro!")
              span({ class = "newsletter-sub" },
                "Receba as novidades do Portal Gamer no seu e-mail.")
            end)
            form({ method  = "POST",
                   action  = "/newsletter/cadastrar",
                   class   = "newsletter-form" }, function()
              input({ type  = "hidden", name  = "origem",
                      value = self.og_url or "/" })
              input({ type        = "email",
                      name        = "email",
                      placeholder = "seu@email.com",
                      class       = "newsletter-input",
                      required    = true })
              button({ type = "submit", class = "newsletter-btn" }, "Inscrever →")
            end)
          end)

          -- Widget de citação aleatória
          div({ id = "citacao-widget", class = "footer-citacao" }, function()
            div({ class = "citacao-aspas" }, "“")
            p({ id = "citacao-texto", class = "citacao-texto" }, "Carregando citação...")
            p({ id = "citacao-fonte", class = "citacao-fonte" })
          end)

          div({ class = "footer-inner" }, function()
            p("© 2026 Portal Gamer — Desenvolvido em Lua com Lapis")
            div({ class = "footer-links" }, function()
              a({ href = "/sobre" },    "Sobre")
              a({ href = "/trending" }, "Trending")
              a({ href = "/rss" },      "RSS Feed")
              a({ href = "/perfil" },   "\xF0\x9F\x91\xA4 Perfil")
              a({ href = "/admin" },    "Admin")
            end)
          end)
        end)
      end)

      script(function()
        raw([[
          (function() {
            var tema = localStorage.getItem('tema') || 'dark';
            var btn  = document.getElementById('tema-toggle');
            if (btn) btn.textContent = tema === 'dark' ? '\u2600\uFE0F' : '\uD83C\uDF19';
          })();

          function toggleTema() {
            var atual = document.documentElement.getAttribute('data-tema') || 'dark';
            var novo  = atual === 'dark' ? 'light' : 'dark';
            document.documentElement.setAttribute('data-tema', novo);
            localStorage.setItem('tema', novo);
            var btn = document.getElementById('tema-toggle');
            if (btn) btn.textContent = novo === 'dark' ? '\u2600\uFE0F' : '\uD83C\uDF19';
          }

          function toggleDrawer() {
            var drawer = document.getElementById('side-drawer');
            var overlay = document.getElementById('drawer-overlay');
            drawer.classList.toggle('aberto');
            overlay.classList.toggle('aberto');
            document.body.style.overflow = drawer.classList.contains('aberto') ? 'hidden' : '';
          }

          function toggleSearch() {
            // Simplificado pois agora está sempre visível no desktop
            var input = document.getElementById('busca-global');
            input.focus();
          }

          // Busca global AJAX
          (function() {
            var input = document.getElementById('busca-global');
            var res   = document.getElementById('busca-resultados');
            if (!input) return;
            var timer = null;
            input.addEventListener('input', function() {
              clearTimeout(timer);
              var termo = input.value.trim();
              if (termo.length < 2) { res.innerHTML=''; res.classList.remove('aberto'); return; }
              timer = setTimeout(function() {
                fetch('/api/busca?q=' + encodeURIComponent(termo))
                  .then(function(r){ return r.json(); })
                  .then(function(data) {
                    if (!data.data||data.data.length===0) {
                      res.innerHTML='<div class="busca-item busca-vazio">Nenhum resultado.</div>';
                    } else {
                      res.innerHTML=data.data.map(function(n){
                        return '<a class="busca-item" href="/noticias/'+n.id+'">'+
                          '<span class="busca-item-titulo">'+n.titulo+'</span>'+
                          '<span class="busca-item-meta">'+
                            '<span class="tag">'+n.categoria+'</span>'+
                            (n.jogo?'<span class="tag tag-jogo">'+n.jogo+'</span>':'')+
                          '</span></a>';
                      }).join('');
                    }
                    res.classList.add('aberto');
                  }).catch(function(){ res.classList.remove('aberto'); });
              }, 280);
            });
            document.addEventListener('click', function(e) {
              var container = document.getElementById('header-busca');
              if (!container.contains(e.target)) {
                res.classList.remove('aberto');
                container.classList.remove('aberto');
                input.value = '';
              }
            });
            input.addEventListener('keydown', function(e) {
              if (e.key==='Escape') { res.classList.remove('aberto'); input.blur(); }
            });
          })();
          // ── Busca por Voz ─────────────────────────────────────────────────
          (function() {
            var btn = document.getElementById('voice-btn');
            if (!btn) return;
            var SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            if (!SpeechRecognition) {
              btn.style.display = 'none';
              return;
            }
            var rec = new SpeechRecognition();
            rec.lang = 'pt-BR';
            rec.interimResults = false;
            rec.maxAlternatives = 1;
            btn.addEventListener('click', function() {
              btn.classList.add('voice-ouvindo');
              btn.textContent = '🔴';
              rec.start();
            });
            rec.onresult = function(e) {
              var termo = e.results[0][0].transcript;
              btn.classList.remove('voice-ouvindo');
              btn.textContent = '🎤';
              // Abre a busca com o termo reconhecido
              var input = document.getElementById('busca-global');
              var headerBusca = document.getElementById('header-busca');
              headerBusca.classList.add('aberto');
              input.value = termo;
              input.dispatchEvent(new Event('input'));
              // Também redireciona para busca avançada se apertar Enter
              input.focus();
            };
            rec.onerror = function() {
              btn.classList.remove('voice-ouvindo');
              btn.textContent = '🎤';
            };
            rec.onend = function() {
              btn.classList.remove('voice-ouvindo');
              if (btn.textContent === '🔴') btn.textContent = '🎤';
            };
            window.iniciarBuscaVoz = function() { rec.start(); };
          })();

          // ── Citação Aleatória ─────────────────────────────────────────────
          (function() {
            var widget = document.getElementById('citacao-widget');
            if (!widget) return;
            fetch('/api/citacao')
              .then(function(r) { return r.json(); })
              .then(function(data) {
                if (data.status !== 'ok') {
                  widget.style.display = 'none';
                  return;
                }
                var texto = document.getElementById('citacao-texto');
                var fonte = document.getElementById('citacao-fonte');
                if (texto) texto.textContent = data.texto;
                if (fonte) {
                  var f = '';
                  if (data.personagem && data.personagem !== '') f += data.personagem;
                  if (data.jogo && data.jogo !== '') f += (f ? ' · ' : '') + data.jogo;
                  fonte.textContent = f ? '— ' + f : '';
                }
              })
              .catch(function() { widget.style.display = 'none'; });
          })();

          // ── PWA: Service Worker ───────────────────────────────────────────
          if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('/sw.js')
              .catch(function() {});
          }
          // Prompt de instalação
          var deferredPrompt;
          window.addEventListener('beforeinstallprompt', function(e) {
            e.preventDefault();
            deferredPrompt = e;
            var btn = document.getElementById('pwa-install-btn');
            if (btn) btn.style.display = 'flex';
          });
          window.instalarPWA = function() {
            if (!deferredPrompt) return;
            deferredPrompt.prompt();
            deferredPrompt.userChoice.then(function() { deferredPrompt = null; });
          };

        ]])
      end)
    end)
  end)
end)