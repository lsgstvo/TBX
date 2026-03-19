local Widget = require("lapis.html").Widget

local function barra_nota(nome, nota)
  nota = tonumber(nota) or 0
  local pct   = math.floor((nota / 10) * 100)
  local cor   = nota >= 8 and "#4ade80" or nota >= 6 and "#f59e0b" or "#f43f5e"
  div({ class = "review-barra-item" }, function()
    div({ class = "review-barra-header" }, function()
      span({ class = "review-barra-nome" }, nome)
      span({ class  = "review-barra-val",
             style  = "color:" .. cor }, string.format("%.1f", nota))
    end)
    div({ class = "review-barra-bg" }, function()
      div({ class = "review-barra-fill",
            style = "width:" .. pct .. "%;background:" .. cor })
    end)
  end)
end

local function estrelas(nota)
  nota = tonumber(nota) or 0
  local cheia = math.floor(nota / 2)
  local meia  = (nota % 2) >= 1 and 1 or 0
  local vazia = 5 - cheia - meia
  return string.rep("★", cheia) .. string.rep("✦", meia) .. string.rep("☆", vazia)
end

return Widget:extend(function(self)
  local r = self.review

  -- Modo leitura
  if self.params and self.params.leitura == "1" then
    div({ class = "leitura-focada" }, function()
      div({ class = "leitura-topbar" }, function()
        a({ href = "/reviews/" .. r.id, class = "leitura-sair" }, "✕ Sair do modo leitura")
        div({ class = "leitura-progresso-wrapper" }, function()
          div({ id = "leitura-barra", class = "leitura-barra" })
        end)
        span({ class = "leitura-tempo" },
          "⏱ " .. tostring(self.tempo_leitura or 1) .. " min")
      end)
      article({ class = "leitura-artigo" }, function()
        span({ class = "cronica-tipo-badge" }, "🎮 Review")
        h1({ class = "leitura-titulo" }, r.titulo)
        div({ class = "leitura-corpo" }, function() p(r.conteudo) end)
      end)
      script(function()
        raw([[
          window.addEventListener('scroll', function() {
            var el=document.documentElement;
            document.getElementById('leitura-barra').style.width=
              (el.scrollTop/(el.scrollHeight-el.clientHeight)*100)+'%';
          });
        ]])
      end)
    end)
    return
  end

  -- Layout normal
  article({ class = "review-artigo shadow-card" }, function()
    -- Header
    div({ class = "review-artigo-header" }, function()
      span({ class = "cronica-tipo-badge" }, "🎮 Review")
      if r.destaque == 1 then
        span({ class = "badge-destaque" }, "⭐ Editor's Choice")
      end
    end)

    -- Capa + título
    local capa = r.imagem_url ~= "" and r.imagem_url or r.jogo_img
    if capa and capa ~= "" then
      img({ src = capa, alt = r.titulo, class = "review-artigo-capa" })
    end

    h1({ class = "review-artigo-titulo" }, r.titulo)

    -- Meta
    div({ class = "review-artigo-meta" }, function()
      a({ href = "/jogos/" .. r.jogo_nome, class = "tag tag-jogo" }, r.jogo_nome)
      if r.genero and r.genero ~= "" then
        span({ class = "tag" }, r.genero)
      end
      if r.autor_nome and r.autor_nome ~= "" then
        span({ class = "meta-sep" }, "·")
        if r.autor_avatar and r.autor_avatar ~= "" then
          img({ src = r.autor_avatar, alt = r.autor_nome, class = "autor-avatar-mini" })
        end
        span({ class = "autor-mini-nome" }, r.autor_nome)
      end
      span({ class = "meta-sep" }, "·")
      span({ class = "meta-item" }, r.criado_em:sub(1,10))
      span({ class = "meta-sep" }, "·")
      span({ class = "meta-item tempo-leitura-badge" },
        "⏱ " .. tostring(self.tempo_leitura or 1) .. " min")
      span({ class = "meta-sep" }, "·")
      a({ href  = "/reviews/" .. r.id .. "?leitura=1",
          class = "meta-leitura" }, "📖 Foco")
    end)

    -- Nota geral (hero)
    div({ class = "review-nota-hero review-nota-hero-grande" }, function()
      div({ class = "review-nota-circulo" .. (
            tonumber(r.nota_geral) >= 8 and " nota-excelente"
            or tonumber(r.nota_geral) >= 6 and " nota-bom"
            or " nota-regular") }, function()
        span({ class = "review-nota-num" },
          string.format("%.1f", tonumber(r.nota_geral) or 0))
        span({ class = "review-nota-max" }, "/10")
      end)
      div(function()
        p({ class = "review-estrelas review-estrelas-lg" }, estrelas(r.nota_geral))
        if r.veredicto and r.veredicto ~= "" then
          p({ class = "review-veredicto-hero" }, r.veredicto)
        end
      end)
    end)

    -- Conteúdo
    div({ class = "review-artigo-corpo" }, function()
      local paragrafos = {}
      for par in (r.conteudo .. "\n\n"):gmatch("(.-)%s*\n%s*\n") do
        par = par:match("^%s*(.-)%s*$")
        if par ~= "" then table.insert(paragrafos, par) end
      end
      if #paragrafos == 0 then
        p(r.conteudo)
      else
        for _, par in ipairs(paragrafos) do
          p({ class = "cronica-par" }, par)
        end
      end
    end)

    -- Notas detalhadas
    div({ class = "review-notas-grid shadow-card" }, function()
      h3("📊 Notas Detalhadas")
      div({ class = "review-barras" }, function()
        barra_nota("🕹 Gameplay",   r.nota_gameplay)
        barra_nota("🖼 Gráficos",   r.nota_graficos)
        barra_nota("📖 História",   r.nota_historia)
        barra_nota("🎵 Áudio",      r.nota_audio)
      end)
    end)

    -- Prós e Contras
    if (r.pros and r.pros ~= "") or (r.contras and r.contras ~= "") then
      div({ class = "review-pros-contras" }, function()
        if r.pros and r.pros ~= "" then
          div({ class = "review-pros" }, function()
            h4("✅ Pontos Positivos")
            ul(function()
              for linha in (r.pros .. "\n"):gmatch("([^\n]+)") do
                if linha:match("%S") then li(linha:match("^%s*(.-)%s*$")) end
              end
            end)
          end)
        end
        if r.contras and r.contras ~= "" then
          div({ class = "review-contras" }, function()
            h4("❌ Pontos Negativos")
            ul(function()
              for linha in (r.contras .. "\n"):gmatch("([^\n]+)") do
                if linha:match("%S") then li(linha:match("^%s*(.-)%s*$")) end
              end
            end)
          end)
        end
      end)
    end

    -- Veredicto final
    if r.veredicto and r.veredicto ~= "" then
      div({ class = "review-veredicto-final" }, function()
        h4("⚖️ Veredicto Final")
        p(r.veredicto)
        div({ class = "review-nota-final" }, function()
          span({ class = "review-nota-num-lg" },
            string.format("%.1f", tonumber(r.nota_geral) or 0))
          span({ class = "review-nota-max-lg" }, "/10")
        end)
      end)
    end

    div({ class = "noticia-footer" }, function()
      a({ href = "/reviews", class = "btn-voltar" }, "← Voltar para Reviews")
      a({ href = "/jogos/" .. r.jogo_nome, class = "btn-ver-mais" },
        "Ver tudo sobre " .. r.jogo_nome .. " →")
    end)
  end)

  -- Barra de progresso de leitura
  script(function()
    raw([[
      (function() {
        var b=document.createElement('div');
        b.style.cssText='position:fixed;top:0;left:0;height:3px;background:var(--primary-color);width:0;z-index:999;transition:width .1s';
        document.body.appendChild(b);
        window.addEventListener('scroll',function(){
          var e=document.documentElement;
          b.style.width=e.scrollHeight>e.clientHeight?
            (e.scrollTop/(e.scrollHeight-e.clientHeight)*100)+'%':'0';
        });
      })();
    ]])
  end)
end)