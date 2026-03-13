-- views/admin/admin_noticia_editar.lua
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("✏️ Editar Notícia")
    if self.erro then div({ class = "alert alert-erro" }, self.erro) end

    div({ class = "form-preview-layout" }, function()

      -- Formulário
      div({ class = "form-col" }, function()
        form({ method = "POST",
               action = "/admin/noticias/" .. self.noticia.id .. "/editar",
               class  = "admin-form" }, function()

          div({ class = "form-group" }, function()
            label({ ["for"] = "titulo" }, "Título *")
            input({ type = "text", id = "titulo", name = "titulo",
                    value = self.noticia.titulo, required = true,
                    oninput = "atualizarPreview()" })
          end)

          div({ class = "form-row" }, function()
            div({ class = "form-group" }, function()
              label({ ["for"] = "jogo" }, "Jogo relacionado")
              element("select", { id = "jogo", name = "jogo",
                                  onchange = "atualizarPreview()" }, function()
                option({ value = "" }, "— Selecione —")
                for _, j in ipairs(self.jogos or {}) do
                  local attrs = { value = j.nome }
                  if j.nome == self.noticia.jogo then attrs.selected = true end
                  option(attrs, j.nome)
                end
              end)
            end)
            div({ class = "form-group" }, function()
              label({ ["for"] = "categoria" }, "Categoria")
              element("select", { id = "categoria", name = "categoria",
                                  onchange = "atualizarPreview()" }, function()
                for _, c in ipairs(self.categorias or {}) do
                  local attrs = { value = c.nome }
                  if c.nome == self.noticia.categoria then attrs.selected = true end
                  option(attrs, c.nome)
                end
              end)
            end)
          end)

          div({ class = "form-group" }, function()
            label({ ["for"] = "conteudo" }, "Conteúdo *")
            textarea({ id = "conteudo", name = "conteudo", rows = "10",
                       required = true, oninput = "atualizarPreview()" },
                     self.noticia.conteudo)
          end)

          div({ class = "form-check" }, function()
            local attrs = { type = "checkbox", id = "destaque", name = "destaque",
                            value = "1", onchange = "atualizarPreview()" }
            if self.noticia.destaque == 1 then attrs.checked = true end
            input(attrs)
            label({ ["for"] = "destaque" }, "⭐ Marcar como destaque na home")
          end)

          div({ class = "form-actions" }, function()
            a({ href = "/admin", class = "btn-cancelar" }, "Cancelar")
            button({ type = "submit", class = "btn-salvar" }, "💾 Salvar Alterações")
          end)
        end)
      end)

      -- Preview ao vivo
      div({ class = "preview-col" }, function()
        div({ class = "preview-header" }, function()
          span({ class = "preview-label" }, "👁 Preview")
          span({ class = "preview-hint" }, "Atualiza em tempo real")
        end)
        div({ id = "preview-box", class = "preview-box" }, function()
          div({ class = "preview-empty" }, "Editando...")
        end)
      end)
    end)
  end)

  -- Script: pré-preenche e mantém atualizado
  script(function()
    raw([[
      function atualizarPreview() {
        var titulo    = document.getElementById('titulo').value;
        var conteudo  = document.getElementById('conteudo').value;
        var jogo      = document.getElementById('jogo').value;
        var categoria = document.getElementById('categoria').value;
        var destaque  = document.getElementById('destaque').checked;
        var box       = document.getElementById('preview-box');

        var hoje = new Date().toISOString().split('T')[0];
        var html = '<article class="noticia-detalhe preview-article">';
        html += '<div class="noticia-header">';
        if (categoria) html += '<span class="tag">' + categoria + '</span>';
        if (jogo)      html += '<span class="tag tag-jogo">' + jogo + '</span>';
        if (destaque)  html += '<span class="badge-destaque">⭐ Destaque</span>';
        html += '<span class="data-noticia">' + hoje + '</span>';
        html += '</div>';
        if (titulo)   html += '<h2>' + titulo + '</h2>';
        html += '<div class="noticia-corpo"><p>' +
                (conteudo || '').replace(/\n/g, '</p><p>') +
                '</p></div>';
        html += '</article>';
        box.innerHTML = html;
      }
      // Pré-preenche o preview ao carregar a página
      window.addEventListener('DOMContentLoaded', atualizarPreview);
    ]])
  end)
end)