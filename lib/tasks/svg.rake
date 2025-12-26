namespace :svg do
  desc "Normalize SVG icons in app/assets/images/icons/"
  task normalize: :environment do
    require "nokogiri"

    # Percorso esatto
    files = Dir.glob(Rails.root.join("app/assets/images/icons/*.svg"))

    if files.empty?
      puts "Nessun file SVG trovato in app/assets/images/icons/"
      next
    end

    files.each do |file_path|
      puts "Normalizing #{File.basename(file_path)}..."

      begin
        svg_content = File.read(file_path)
        doc = Nokogiri::XML(svg_content) do |config|
          config.strict.nonet
        end

        svg_node = doc.at_css("svg")
        next unless svg_node

        # 1. GESTIONE VIEWBOX (Cruciale!)
        # Se manca il viewBox, proviamo a crearlo da width/height prima di cancellarli
        unless svg_node["viewBox"]
          w = svg_node["width"].to_f.to_i
          h = svg_node["height"].to_f.to_i
          if w > 0 && h > 0
            svg_node["viewBox"] = "0 0 #{w} #{h}"
            puts "  -> ViewBox mancante creato: 0 0 #{w} #{h}"
          end
        end

        # 2. Rimuovi dimensioni fisse (ora è sicuro farlo)
        svg_node.remove_attribute("width")
        svg_node.remove_attribute("height")

        # 3. Pulizia attributi "sporchi"
        svg_node.remove_attribute("class")
        svg_node.remove_attribute("style")
        svg_node.remove_attribute("id") # Rimuovi ID dal root per evitare duplicati in pagina
        doc.css("*[style]").each { |el| el.remove_attribute("style") }

        # Rimuovi ID interni (es. definiti da Illustrator), a meno che non siano referenziati (raro in icone semplici)
        # Se usi icone complesse con <defs> e <use>, rimuovere gli ID potrebbe rompere l'icona.
        # Per icone tipo Material Symbols/FontAwesome, è sicuro rimuoverli.
        doc.css("*[id]").each { |el| el.remove_attribute("id") }

        # 4. Normalizzazione Colori (CurrentColor)
        # Strategia: Se un elemento ha un fill/stroke specifico, lo forza a currentColor.
        # Se è "none", lo lascia "none".

        # Imposta currentColor di default sul nodo SVG se non ha fill="none"
        svg_node["fill"] = "currentColor" unless svg_node["fill"] == "none"

        doc.css("*").each do |el|
          # Gestione FILL
          if el["fill"] && el["fill"] != "none"
            el["fill"] = "currentColor"
          end

          # Gestione STROKE
          if el["stroke"] && el["stroke"] != "none"
            el["stroke"] = "currentColor"
          end
        end

        # 5. Rimuovi metadati inutili
        doc.css("title, desc, metadata, defs").each(&:remove)
        doc.xpath("//comment()").remove

        # Opzioni di salvataggio: XML puro, niente dichiarazione <?xml ...?>
        save_options = Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION

        # Sovrascrivi
        File.write(file_path, doc.to_xml(indent: 0, save_with: save_options).strip)

      rescue Nokogiri::XML::SyntaxError => e
        puts "  -> ERRORE XML: #{e.message}"
      rescue StandardError => e
        puts "  -> ERRORE Generico: #{e.message}"
      end
    end
    puts "SVG normalization complete. ✨"
  end
end
