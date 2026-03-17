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
      link({ href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap",
             rel  = "stylesheet" })
    end)

    body(function()
      header({ class = "site-header" }, function()
        div({ class = "container header-inner" }, function()
          a({ href = "/", class = "site-brand" }, "Portal Gamer")
          
          nav({ class = "header-nav" }, function()
            a({ href = "/" },         "Início")
            a({ href = "/noticias" }, "Notícias")
            a({ href = "/trending" }, "🔥 Trending")
            a({ href = "/ranking" },  "Ranking")
            a({ href = "/sobre" },    "Sobre")
            a({ href = "/feed" },      "⚡ Feed")
            a({ href = "/glossario" }, "📖 Glossário")
            a({ href = "/admin" },    "Admin")
          end)

          div({ class = "header-actions" }, function()
            div({ class = "header-busca", id = "header-busca" }, function()
              button({ id = "search-toggle", class = "search-toggle-btn", title = "Pesquisar", onclick = "toggleSearch()" }, "🔍")
              button({ id = "voice-btn", class = "search-toggle-btn voice-btn",
                       title = "Busca por voz", onclick = "iniciarBuscaVoz()" }, "🎤")
              input({ type = "text", id = "busca-global", class = "busca-global-input",
                      placeholder = "Buscar notícias...", autocomplete = "off" })
              div({ id = "busca-resultados", class = "busca-resultados" })
            end)
            
            a({ href = "/perfil", class = "nav-perfil-btn" }, (self.leitor_icon or "👤") .. " " .. (self.leitor_nome or "Perfil"))
            -- Sino de notificações
            div({ class = "notif-wrapper", id = "notif-wrapper" }, function()
              button({ id    = "notif-btn",
                       class = "search-toggle-btn notif-btn",
                       title = "Notificações",
                       onclick = "toggleNotificacoes()" }, function()
                span("🔔")
                span({ id = "notif-badge", class = "notif-badge", style = "display:none" }, "0")
              end)
              div({ id = "notif-dropdown", class = "notif-dropdown" }, function()
                div({ class = "notif-header" }, function()
                  span({ class = "notif-titulo" }, "Notificações")
                  button({ class = "notif-marcar-btn",
                           onclick = "marcarTodasLidas()" }, "Marcar como lidas")
                end)
                div({ id = "notif-lista", class = "notif-lista" }, function()
                  p({ class = "notif-vazia" }, "Sem notificações.")
                end)
              end)
            end)
            
            button({ id = "tema-toggle", class = "tema-btn",
                     title = "Alternar tema", onclick = "toggleTema()" }, "☀️")
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

          function toggleSearch() {
            var headerBusca = document.getElementById('header-busca');
            var input = document.getElementById('busca-global');
            var isAberto = headerBusca.classList.toggle('aberto');
            if (isAberto) {
              input.focus();
            } else {
              input.value = '';
              document.getElementById('busca-resultados').innerHTML = '';
              document.getElementById('busca-resultados').classList.remove('aberto');
            }
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

          // ── Notificações in-app ───────────────────────────────────────────
          (function() {
            var POLL_INTERVAL = 30000; // 30s
            var dropdown = document.getElementById('notif-dropdown');
            var badge    = document.getElementById('notif-badge');
            var lista    = document.getElementById('notif-lista');

            function carregarNotifs() {
              fetch('/api/notificacoes')
                .then(function(r){ return r.json(); })
                .then(function(data) {
                  if (data.status !== 'ok') return;
                  var naoLidas = data.nao_lidas || 0;
                  if (badge) {
                    badge.textContent = naoLidas > 9 ? '9+' : String(naoLidas);
                    badge.style.display = naoLidas > 0 ? 'flex' : 'none';
                  }
                  if (!lista) return;
                  if (!data.notificacoes || data.notificacoes.length === 0) {
                    lista.innerHTML = '<p class="notif-vazia">Sem notificações.</p>';
                    return;
                  }
                  var html = '';
                  data.notificacoes.forEach(function(n) {
                    var cls = 'notif-item' + (n.lida ? '' : ' notif-nao-lida');
                    html += '<div class="' + cls + '">';
                    if (n.link && n.link !== '') {
                      html += '<a href="' + n.link + '" class="notif-link">';
                    }
                    html += '<div class="notif-item-titulo">' + n.titulo + '</div>';
                    if (n.mensagem) html += '<div class="notif-item-msg">' + n.mensagem + '</div>';
                    html += '<div class="notif-item-data">' + n.criado_em.substring(0,16) + '</div>';
                    if (n.link && n.link !== '') html += '</a>';
                    html += '<button class="notif-del" onclick="deletarNotif(' + n.id + ')">✕</button>';
                    html += '</div>';
                  });
                  lista.innerHTML = html;
                })
                .catch(function(){});
            }

            window.toggleNotificacoes = function() {
              if (!dropdown) return;
              var aberto = dropdown.classList.toggle('notif-aberto');
              if (aberto) carregarNotifs();
            };
            window.marcarTodasLidas = function() {
              fetch('/api/notificacoes/lidas', { method: 'POST' })
                .then(function(){ carregarNotifs(); });
            };
            window.deletarNotif = function(id) {
              fetch('/api/notificacoes/' + id + '/deletar', { method: 'POST' })
                .then(function(){ carregarNotifs(); });
            };

            // Fecha ao clicar fora
            document.addEventListener('click', function(e) {
              var w = document.getElementById('notif-wrapper');
              if (w && !w.contains(e.target) && dropdown) {
                dropdown.classList.remove('notif-aberto');
              }
            });

            // Poll periódico
            carregarNotifs();
            setInterval(carregarNotifs, POLL_INTERVAL);
          })();

        ]])
      end)
    end)
  end)
end)