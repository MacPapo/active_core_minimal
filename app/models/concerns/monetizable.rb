module Monetizable
  extend ActiveSupport::Concern

  class_methods do
    def monetize(attribute_name)
      cents_column = "#{attribute_name}_cents"

      # 1. GETTER (DB -> View)
      define_method(attribute_name) do
        cents = send(cents_column)
        return nil unless cents
        cents / 100.0
      end

      # 2. SETTER (View -> DB)
      define_method("#{attribute_name}=") do |value|
        return send("#{cents_column}=", nil) if value.blank?

        if value.is_a?(Numeric)
          self.send("#{cents_column}=", (value * 100).to_i)
        else
          # A. Pulizia base: teniamo solo numeri, punti, virgole e segno meno
          clean_string = value.to_s.gsub(/[^\d.,-]/, "")

          # B. Gestione avanzata separatori (Migliaia vs Decimali)
          # Se ci sono SIA punti CHE virgole, dobbiamo capire chi fa cosa.
          if clean_string.include?(".") && clean_string.include?(",")
            last_dot_index = clean_string.rindex(".")
            last_comma_index = clean_string.rindex(",")

            if last_dot_index < last_comma_index
              # Formato IT: 1.200,50 -> Il punto viene prima, quindi è migliaia. Lo togliamo.
              clean_string = clean_string.gsub(".", "")
            else
              # Formato US: 1,200.50 -> La virgola viene prima, quindi è migliaia. La togliamo.
              clean_string = clean_string.gsub(",", "")
            end
          end

          # C. Standardizzazione finale: virgola diventa sempre punto decimale
          standardized_string = clean_string.gsub(",", ".")

          # D. Conversione sicura
          self.send("#{cents_column}=", (BigDecimal(standardized_string) * 100).to_i)
        end
      end
    end
  end
end
