-- views/admin/admin_noticia_form.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("➕ Nova Notícia")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    -- Layout: form à esquerda, preview à direita
    div({ class = "form-preview-layout" }, function()

      -- Formulário
      div({ class = "form-col" }, function()
        form({ method = "POST", action = "/admin/noticias/nova",
               class  = "admin-form", id = "form-noticia" }, function()

          div({ class = "form-group" }, function()
            label({ ["for"] = "titulo" }, "Título *")
            input({ type = "text", id = "titulo", name = "titulo",
                    placeholder = "Ex: Novo update de Valorant!",
                    required = true, oninput = "atualizarPreview()" })
          end)

          div({ class = "form-row" }, function()
            div({ class = "form-group" }, function()
              label({ ["for"] = "jogo" }, "Jogo relacionado")
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
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "conteudo" }, "Conteúdo *")
            textarea({ id = "conteudo", name = "conteudo", rows = "10",
                       placeholder = "Escreva o conteúdo completo...",
                       required = true, oninput = "atualizarPreview()" })
          end)

          div({ class = "form-check" }, function()
            input({ type = "checkbox", id = "destaque", name = "destaque",
                    value = "1", onchange = "atualizarPreview()" })
            label({ ["for"] = "destaque" }, "⭐ Marcar como destaque na home")
          end)

          div({ class = "form-actions" }, function()
            a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
            button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Notícia")
          end)
        end)
      end)

      -- Painel de preview ao vivo
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

  -- Script de preview ao vivo
  script(function()
    raw([[
      function atualizarPreview() {
        var titulo    = document.getElementById('titulo').value;
        var conteudo  = document.getElementById('conteudo').value;
        var jogo      = document.getElementById('jogo').value;
        var categoria = document.getElementById('categoria').value;
        var destaque  = document.getElementById('destaque').checked;
        var box       = document.getElementById('preview-box');

        if (!titulo && !conteudo) {
          box.innerHTML = '<div class="preview-empty">Preencha o formulário para ver o preview →</div>';
          return;
        }

        var hoje = new Date().toISOString().split('T')[0];

        var html = '<article class="noticia-detalhe preview-article">';

        // Header com tags
        html += '<div class="noticia-header">';
        if (categoria) html += '<span class="tag">' + categoria + '</span>';
        if (jogo)      html += '<span class="tag tag-jogo">' + jogo + '</span>';
        if (destaque)  html += '<span class="badge-destaque">⭐ Destaque</span>';
        html += '<span class="data-noticia">' + hoje + '</span>';
        html += '</div>';

        // Título
        if (titulo) html += '<h2>' + titulo + '</h2>';

        // Meta
        html += '<div class="noticia-meta">';
        html += '<span class="meta-item">👁 0 visualizações</span>';
        html += '<span class="meta-sep">·</span>';
        html += '<span class="meta-item">💬 0 comentários</span>';
        html += '</div>';

        // Corpo
        if (conteudo) {
          html += '<div class="noticia-corpo"><p>' +
                  conteudo.replace(/\n/g, '</p><p>') +
                  '</p></div>';
        }

        html += '</article>';
        box.innerHTML = html;
      }
    ]])
  end)
end)