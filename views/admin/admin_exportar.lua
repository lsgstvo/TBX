local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  div({ class = "admin-section shadow-card" }, function()
    h2("📥 Exportar Dados")
    p({ class = "sem-dados", style = "margin-bottom:1.5rem" },
      "Exporte os dados do portal em formato CSV, compatível com Excel, Google Sheets e qualquer editor de planilhas.")

    div({ class = "exportar-grid" }, function()

      -- Notícias
      div({ class = "exportar-card" }, function()
        div({ class = "exportar-ico" }, "📰")
        h3("Notícias")
        p({ class = "exportar-desc" },
          "Exporta todas as notícias com ID, título, categoria, jogo, views, curtidas, autor e data.")
        a({ href   = "/admin/exportar/noticias.csv",
            class  = "btn-exportar",
            target = "_blank" }, "⬇️ Baixar noticias.csv")
      end)

      -- Comentários
      div({ class = "exportar-card" }, function()
        div({ class = "exportar-ico" }, "💬")
        h3("Comentários")
        p({ class = "exportar-desc" },
          "Exporta todos os comentários com autor, conteúdo, status de aprovação e notícia associada.")
        a({ href   = "/admin/exportar/comentarios.csv",
            class  = "btn-exportar",
            target = "_blank" }, "⬇️ Baixar comentarios.csv")
      end)

      -- Newsletter
      div({ class = "exportar-card" }, function()
        div({ class = "exportar-ico" }, "📧")
        h3("Newsletter")
        p({ class = "exportar-desc" },
          "Exporta a lista de e-mails inscritos ativos na newsletter.")
        a({ href   = "/admin/exportar/newsletter.csv",
            class  = "btn-exportar",
            target = "_blank" }, "⬇️ Baixar newsletter.csv")
      end)

    end)

    div({ class = "exportar-aviso" }, function()
      p("⚠️ Os arquivos CSV usam codificação UTF-8. "
        .. "Ao abrir no Excel, use Dados → De Texto/CSV e selecione UTF-8 "
        .. "para evitar problemas com acentos.")
    end)
  end)
end)