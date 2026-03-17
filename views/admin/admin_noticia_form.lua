local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("➕ Nova Notícia")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    div({ class = "form-preview-layout" }, function()

      div({ class = "form-col" }, function()
        form({ method = "POST", action = "/admin/noticias/nova",
               class = "admin-form", id = "form-noticia",
               enctype = "multipart/form-data" }, function()

          div({ class = "form-group" }, function()
            label({ ["for"] = "titulo" }, "Título *")
            input({ type = "text", id = "titulo", name = "titulo",
                    placeholder = "Ex: Novo update de Valorant!",
                    required = true, oninput = "atualizarPreview()" })
          end)

          div({ class = "form-row" }, function()
            div({ class = "form-group" }, function()
              label({ ["for"] = "jogo" }, "Jogo")
              element("select", { id = "jogo", name = "jogo",
                                  onchange = "atualizarPreview()" }, function()
                option({ value = "" }, "— Selecione —")
                for _, j in ipairs(self.jogos or {}) do
                  option({ value = j.nome }, j.nome)
                end
              end)
            end)
            div({ class = "form-group" }, function()
              label({ ["for"] = "categoria" }, "Categoria")
              element("select", { id = "categoria", name = "categoria",
                                  onchange = "atualizarPreview()" }, function()
                for _, c in ipairs(self.categorias or {}) do
                  option({ value = c.nome }, c.nome)
                end
              end)
            end)
            div({ class = "form-group" }, function()
              label({ ["for"] = "autor_id" }, "Autor")
              element("select", { id = "autor_id", name = "autor_id" }, function()
                option({ value = "" }, "— Selecione —")
                for _, a in ipairs(self.autores or {}) do
                  option({ value = tostring(a.id) }, a.nome)
                end
              end)
            end)
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "conteudo" }, "Conteúdo *")
            textarea({ id = "conteudo", name = "conteudo", rows = "9",
                       placeholder = "Escreva o conteúdo completo...",
                       required = true, oninput = "atualizarPreview()" })
          end)

          -- Tags com sugestão por IA
          div({ class = "form-group" }, function()
            label({ ["for"] = "tags" }, "Tags")
            div({ class = "tags-ia-wrapper" }, function()
              input({ type = "text", id = "tags", name = "tags",
                      placeholder = "ex: fps, competitivo, update",
                      autocomplete = "off" })
              button({ type    = "button",
                       id      = "btn-sugerir-tags",
                       class   = "btn-ia",
                       onclick = "sugerirTagsIA()",
                       title   = "Sugerir tags com IA" }, function()
                span({ id = "ia-ico" }, "✨")
                span({ id = "ia-txt" }, "IA")
              end)
            end)
            -- Tags populares manuais
            if self.tags_pop and #self.tags_pop > 0 then
              div({ class = "tags-sugestoes" }, function()
                span({ class = "sugestao-label" }, "Populares: ")
                for _, t in ipairs(self.tags_pop) do
                  button({ type    = "button", class = "tag-sugestao",
                           onclick = "adicionarTag('" .. t.nome .. "')" },
                         "#" .. t.nome)
                end
              end)
            end
            -- Área de sugestões da IA
            div({ id = "ia-sugestoes", class = "ia-sugestoes" })
          end)

          -- Upload de imagem
          div({ class = "form-group" }, function()
            label({}, "Imagem de Capa")
            div({ class = "upload-wrapper" }, function()
              input({ type = "file", id = "upload-arquivo",
                      accept = "image/jpeg,image/png,image/gif,image/webp",
                      class  = "upload-input", onchange = "fazerUpload(this)" })
              div({ id = "upload-status",  class = "upload-status" })
              div({ id = "upload-preview", class = "upload-img-preview" })
            end)
            input({ type = "hidden", id = "imagem_url", name = "imagem_url" })
          end)

          -- Agendamento
          div({ class = "form-group" }, function()
            label({ ["for"] = "publicar_em" }, "⏰ Agendar publicação (opcional)")
            input({ type  = "datetime-local", id = "publicar_em", name = "publicar_em" })
            p({ class = "field-hint" }, "Deixe vazio para publicar imediatamente.")
          end)

          div({ class = "form-check" }, function()
            input({ type = "checkbox", id = "destaque", name = "destaque",
                    value = "1", onchange = "atualizarPreview()" })
            label({ ["for"] = "destaque" }, "⭐ Destaque na home")
          end)

          div({ class = "form-actions" }, function()
            a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
            button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Notícia")
          end)
        end)
      end)

      div({ class = "preview-col" }, function()
        div({ class = "preview-header" }, function()
          span({ class = "preview-label" }, "👁 Preview")
          span({ class = "preview-hint" }, "Atualiza em tempo real")
        end)
        div({ id = "preview-box", class = "preview-box" }, function()
          div({ class = "preview-empty" }, "Preencha o formulário para ver o preview →")
        end)
      end)
    end)
  end)

  script(function()
    raw([[
      // ── Upload de imagem ─────────────────────────────────────────────
      function fazerUpload(input) {
        var arquivo = input.files[0]; if (!arquivo) return;
        var status  = document.getElementById('upload-status');
        var preview = document.getElementById('upload-preview');
        var hidden  = document.getElementById('imagem_url');
        status.textContent = '⏳ Enviando...';
        status.className   = 'upload-status upload-enviando';
        var fd = new FormData(); fd.append('imagem', arquivo);
        fetch('/admin/upload/imagem', { method:'POST', body:fd })
          .then(function(r){ return r.json(); })
          .then(function(data){
            if (data.status==='ok') {
              hidden.value = data.url;
              status.textContent = '✅ Upload concluído!';
              status.className   = 'upload-status upload-ok';
              preview.innerHTML  = '<img src="'+data.url+'" class="upload-thumb"/>';
              atualizarPreview();
            } else {
              status.textContent = '❌ '+(data.mensagem||'Erro.');
              status.className   = 'upload-status upload-erro';
            }
          }).catch(function(){ status.textContent='❌ Erro de conexão.'; });
      }

      // ── Tags manuais ─────────────────────────────────────────────────
      function adicionarTag(nome) {
        var input = document.getElementById('tags');
        var lista = input.value.trim()
          ? input.value.trim().split(',').map(function(t){return t.trim();}) : [];
        if (lista.indexOf(nome) === -1) { lista.push(nome); input.value = lista.join(', '); }
      }

      // ── Sugestão de Tags por IA ──────────────────────────────────────
      function sugerirTagsIA() {
        var titulo   = document.getElementById('titulo').value.trim();
        var conteudo = document.getElementById('conteudo').value.trim();
        var jogo     = document.getElementById('jogo').value;
        var icoEl    = document.getElementById('ia-ico');
        var txtEl    = document.getElementById('ia-txt');
        var box      = document.getElementById('ia-sugestoes');

        if (!titulo && !conteudo) {
          box.innerHTML = '<span class="ia-erro">Preencha o título ou conteúdo primeiro.</span>';
          box.classList.add('ia-ativo');
          return;
        }

        // Indica carregamento
        if (icoEl) icoEl.textContent = '⏳';
        if (txtEl) txtEl.textContent = '...';
        box.innerHTML = '<span class="ia-carregando">✨ A IA está pensando...</span>';
        box.classList.add('ia-ativo');

        // Passo 1: busca o prompt montado pelo servidor
        fetch('/api/sugerir-tags', {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: 'titulo=' + encodeURIComponent(titulo)
              + '&conteudo=' + encodeURIComponent(conteudo.substring(0, 600))
              + '&jogo=' + encodeURIComponent(jogo)
        })
        .then(function(r){ return r.json(); })
        .then(function(data) {
          if (data.status !== 'ok') {
            box.innerHTML = '<span class="ia-erro">Erro: ' + (data.mensagem||'tente novamente') + '</span>';
            if (icoEl) icoEl.textContent = '✨';
            if (txtEl) txtEl.textContent = 'IA';
            return;
          }
          // Passo 2: chama a API da Anthropic diretamente
          return fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              model: 'claude-sonnet-4-20250514',
              max_tokens: 100,
              messages: [{ role: 'user', content: data.prompt }]
            })
          });
        })
        .then(function(r){ return r && r.json(); })
        .then(function(resp) {
          if (icoEl) icoEl.textContent = '✨';
          if (txtEl) txtEl.textContent = 'IA';
          if (!resp || !resp.content || !resp.content[0]) {
            box.innerHTML = '<span class="ia-erro">Sem resposta da IA.</span>';
            return;
          }
          var texto = resp.content[0].text || '';
          var sugestoes = texto.split(',')
            .map(function(t){ return t.trim().toLowerCase().replace(/[^a-z0-9\u00c0-\u024f\s-]/g,''); })
            .filter(function(t){ return t.length > 0 && t.length < 30; });

          if (sugestoes.length === 0) {
            box.innerHTML = '<span class="ia-erro">A IA não retornou tags válidas.</span>';
            return;
          }

          // Renderiza botões de sugestão
          var html = '<span class="sugestao-label">✨ Sugestões da IA:</span>';
          sugestoes.forEach(function(tag) {
            html += '<button type="button" class="tag-sugestao tag-ia-sug" '
                  + 'onclick="adicionarTag(\'' + tag.replace(/'/g,"\\'") + '\')">'
                  + '#' + tag + '</button>';
          });
          html += '<button type="button" class="ia-add-todas" '
                + 'onclick="adicionarTodasIA([' + sugestoes.map(function(t){return "'"+t.replace(/'/g,"\\'")+"'";}).join(',') + '])">'
                + 'Adicionar todas</button>';
          box.innerHTML = html;
        })
        .catch(function(err) {
          if (icoEl) icoEl.textContent = '✨';
          if (txtEl) txtEl.textContent = 'IA';
          box.innerHTML = '<span class="ia-erro">Erro de conexão com a IA.</span>';
        });
      }

      function adicionarTodasIA(tags) {
        tags.forEach(function(t){ adicionarTag(t); });
      }

      // ── Preview ao vivo ──────────────────────────────────────────────
      function atualizarPreview() {
        var titulo   = document.getElementById('titulo').value;
        var conteudo = document.getElementById('conteudo').value;
        var jogo     = document.getElementById('jogo').value;
        var cat      = document.getElementById('categoria').value;
        var dest     = document.getElementById('destaque').checked;
        var imgUrl   = document.getElementById('imagem_url').value;
        var box      = document.getElementById('preview-box');
        if (!titulo && !conteudo) {
          box.innerHTML = '<div class="preview-empty">Preencha para ver o preview →</div>';
          return;
        }
        var hoje = new Date().toISOString().split('T')[0];
        var html = '<article class="noticia-detalhe preview-article">';
        html += '<div class="noticia-header">';
        if (cat)  html += '<span class="tag">'+cat+'</span>';
        if (jogo) html += '<span class="tag tag-jogo">'+jogo+'</span>';
        if (dest) html += '<span class="badge-destaque">⭐ Destaque</span>';
        html += '<span class="data-noticia">'+hoje+'</span></div>';
        if (imgUrl) html += '<img src="'+imgUrl+'" style="width:100%;border-radius:8px;margin:.8rem 0;max-height:180px;object-fit:cover"/>';
        if (titulo) html += '<h2>'+titulo+'</h2>';
        html += '<div class="noticia-corpo"><p>'+(conteudo||'').replace(/\n/g,'</p><p>')+'</p></div>';
        html += '</article>';
        box.innerHTML = html;
      }
    ]])
  end)
end)