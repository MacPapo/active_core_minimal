module IconsHelper
  def icon(name, size: 20, **options)
    # Percorso del file SVG
    filename = Rails.root.join("app/assets/images/icons/#{name}.svg")

    # Fallback se l'icona non esiste: mostra un quadratino con l'iniziale
    unless File.exist?(filename)
      return content_tag(:span, name.to_s.first.upcase,
                         class: "icon-placeholder inline-flex items-center justify-center bg-base-300 rounded text-xs font-bold select-none #{options[:class]}",
                         style: "width: #{size}px; height: #{size}px;")
    end

    # Cache key: include il nome del file e la data di modifica (mtime)
    # Se modifichi il file SVG, la cache si aggiorna da sola.
    cache_key = [ "icon_svg_v1", name, File.mtime(filename) ]

    svg_content = Rails.cache.fetch(cache_key) do
      File.read(filename)
    end

    # Parsing con Nokogiri per modificare le dimensioni e le classi al volo
    doc = Nokogiri::HTML::DocumentFragment.parse(svg_content)
    svg = doc.at_css("svg")

    # Imposta dimensioni
    svg["width"] = size.to_s
    svg["height"] = size.to_s

    # Aggiungi classi CSS (merge con quelle esistenti nell'SVG se ce ne sono)
    if options[:class].present?
      existing_class = svg["class"] || ""
      svg["class"] = "#{existing_class} #{options[:class]}".strip
    end

    # Aggiungi eventuali altri attributi passati nelle options
    options.except(:class).each do |key, value|
      svg[key.to_s.dasherize] = value
    end

    # Restituisce HTML sicuro
    doc.to_html.html_safe
  end
end
