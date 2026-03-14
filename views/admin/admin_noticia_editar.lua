-- views/admin/admin_noticia_editar.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("✏️ Editar Notícia")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    div({ class = "form-preview-layout" }, function()

      -- Formulário
      div({ class = "form-col" }, function()
        form({ method  = "POST",
               action  = "/admin/noticias/" .. self.noticia.id .. "/editar",
               class   = "admin-form",
               enctype = "multipart/form-data" }, function()

          div({ class = "form-group" }, function()
            label({ ["for"] = "titulo" }, "Título *")
            input({ type = "text", id = "titulo", name = "titulo",
                    value = self.noticia.titulo, required = true,
                    oninput = "atualizarPreview()" })
          end)

          div({ class = "form-row" }, function()
            div({ class = "form-group" }, function()
              label({ ["for"] = "jogo" }, "Jogo")
              element("select", { id = "jogo", name = "jogo",
                                  onchange = "atualizarPreview()" }, function()
                option({ value = "" }, "— Selecione —")
                for _, j in ipairs(self.jogos or {}) do
                  local a = { value = j.nome }
                  if j.nome == self.noticia.jogo then a.selected = true end
                  option(a, j.nome)
                end
              end)
            end)
            div({ class = "form-group" }, function()
              label({ ["for"] = "categoria" }, "Categoria")
              element("select", { id = "categoria", name = "categoria",
                                  onchange = "atualizarPreview()" }, function()
                for _, c in ipairs(self.categorias or {}) do
                  local a = { value = c.nome }
                  if c.nome == self.noticia.categoria then a.selected = true end
                  option(a, c.nome)
                end
              end)
            end)
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "conteudo" }, "Conteúdo *")
            textarea({ id = "conteudo", name = "conteudo", rows = "9",
                       required = true, oninput = "atualizarPreview()" },
                     self.noticia.conteudo)
          end)

          -- Campo de tags com sugestões
          div({ class = "form-group" }, function()
            label({ ["for"] = "tags" }, "Tags")
            input({ type        = "text",
                    id          = "tags",
                    name        = "tags",
                    value       = self.tags_str or "",
                    placeholder = "ex: fps, competitivo, update",
                    autocomplete = "off" })
            -- Sugestões de tags populares
            if self.tags_pop and #self.tags_pop > 0 then
              div({ class = "tags-sugestoes" }, function()
                span({ class = "sugestao-label" }, "Populares: ")
                for _, t in ipairs(self.tags_pop) do
                  button({ type    = "button",
                           class   = "tag-sugestao",
                           onclick = "adicionarTag('" .. t.nome .. "')" },
                         "#" .. t.nome)
                end
              end)
            end
          end)

          -- Upload de imagem
          div({ class = "form-group" }, function()
            label({}, "Imagem de Capa")
            -- Mostra imagem atual se houver
            if self.noticia.imagem_url and self.noticia.imagem_url ~= "" then
              div({ class = "img-preview" }, function()
                p({ class = "preview-label" }, "Atual:")
                img({ src   = self.noticia.imagem_url,
                      alt   = self.noticia.titulo,
                      class = "preview-img",
                      id    = "img-atual" })
              end)
            end
            div({ class = "upload-wrapper" }, function()
              input({ type     = "file",
                      id       = "upload-arquivo",
                      accept   = "image/jpeg,image/png,image/gif,image/webp",
                      class    = "upload-input",
                      onchange = "fazerUpload(this)" })
              div({ id = "upload-status",  class = "upload-status" })
              div({ id = "upload-preview", class = "upload-img-preview" })
            end)
            input({ type  = "hidden",
                    id    = "imagem_url",
                    name  = "imagem_url",
                    value = self.noticia.imagem_url or "" })
          end)

          div({ class = "form-check" }, function()
            local attrs = { type = "checkbox", id = "destaque", name = "destaque",
                            value = "1", onchange = "atualizarPreview()" }
            if self.noticia.destaque == 1 then attrs.checked = true end
            input(attrs)
            label({ ["for"] = "destaque" }, "⭐ Destaque na home")
          end)

          div({ class = "form-actions" }, function()
            a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
            button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Alterações")
          end)
        end)
      end)

      -- Preview + Histórico
      div({ class = "preview-col" }, function()
        div({ class = "preview-header" }, function()
          span({ class = "preview-label" }, "👁 Preview")
          span({ class = "preview-hint" }, "Atualiza em tempo real")
        end)
        div({ id = "preview-box", class = "preview-box" })

        -- Histórico de edições
        if self.historico and #self.historico > 0 then
          div({ class = "historico-wrapper mt-2" }, function()
            h4("🕓 Histórico de Edições (" .. #self.historico .. ")")
            div({ class = "historico-lista" }, function()
              for i, h in ipairs(self.historico) do
                div({ class = "historico-item" .. (i == 1 and " historico-recente" or "") }, function()
                  div({ class = "historico-meta" }, function()
                    span({ class = "historico-data" }, h.editado_em:sub(1, 16))
                  end)
                  p({ class = "historico-titulo" }, h.titulo_ant)
                  p({ class = "historico-preview" }, h.conteudo_ant:sub(1, 80) .. "...")
                end)
              end
            end)
          end)
        end
      end)
    end)
  end)

  script(function()
    raw([[
      // ── Upload ────────────────────────────────────────────────────────
      function fazerUpload(input) {
        var arquivo = input.files[0];
        if (!arquivo) return;
        var status  = document.getElementById('upload-status');
        var preview = document.getElementById('upload-preview');
        var hidden  = document.getElementById('imagem_url');
        status.textContent = '⏳ Enviando...';
        status.className   = 'upload-status upload-enviando';
        preview.innerHTML  = '';
        var formData = new FormData();
        formData.append('imagem', arquivo);
        fetch('/admin/upload/imagem', { method: 'POST', body: formData })
          .then(function(r) { return r.json(); })
          .then(function(data) {
            if (data.status === 'ok') {
              hidden.value       = data.url;
              status.textContent = '✅ Upload concluído!';
              status.className   = 'upload-status upload-ok';
              preview.innerHTML  = '<img src="' + data.url + '" class="upload-thumb"/>';
              var atual = document.getElementById('img-atual');
              if (atual) atual.src = data.url;
            } else {
              status.textContent = '❌ ' + (data.mensagem || 'Erro.');
              status.className   = 'upload-status upload-erro';
            }
          })
          .catch(function() {
            status.textContent = '❌ Erro de conexão.';
            status.className   = 'upload-status upload-erro';
          });
      }

      // ── Tags ──────────────────────────────────────────────────────────
      function adicionarTag(nome) {
        var input = document.getElementById('tags');
        var atual = input.value.trim();
        var lista = atual ? atual.split(',').map(function(t){return t.trim();}) : [];
        if (lista.indexOf(nome) === -1) {
          lista.push(nome);
          input.value = lista.join(', ');
        }
      }

      // ── Preview ───────────────────────────────────────────────────────
      function atualizarPreview() {
        var titulo   = document.getElementById('titulo').value;
        var conteudo = document.getElementById('conteudo').value;
        var jogo     = document.getElementById('jogo').value;
        var cat      = document.getElementById('categoria').value;
        var dest     = document.getElementById('destaque').checked;
        var imgUrl   = document.getElementById('imagem_url').value;
        var box      = document.getElementById('preview-box');

        var hoje = new Date().toISOString().split('T')[0];
        var html = '<article class="noticia-detalhe preview-article">';
        html += '<div class="noticia-header">';
        if (cat)  html += '<span class="tag">' + cat + '</span>';
        if (jogo) html += '<span class="tag tag-jogo">' + jogo + '</span>';
        if (dest) html += '<span class="badge-destaque">⭐ Destaque</span>';
        html += '<span class="data-noticia">' + hoje + '</span>';
        html += '</div>';
        if (imgUrl) html += '<img src="' + imgUrl +
          '" style="width:100%;border-radius:8px;margin:.8rem 0;max-height:180px;object-fit:cover"/>';
        if (titulo) html += '<h2>' + titulo + '</h2>';
        html += '<div class="noticia-corpo"><p>' +
                (conteudo||'').replace(/\n/g,'</p><p>') +
                '</p></div></article>';
        box.innerHTML = html;
      }

      window.addEventListener('DOMContentLoaded', atualizarPreview);
    ]])
  end)
end)