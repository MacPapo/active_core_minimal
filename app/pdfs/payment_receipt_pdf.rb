class PaymentReceiptPdf < ApplicationPdf
  # --- LAYOUT CONSTANTS ---
  HEADER_LEFT_WIDTH    = 360
  HEADER_RIGHT_WIDTH   = 180
  HEADER_RIGHT_X       = 350
  RECIPIENT_BOX_WIDTH  = 400
  TABLE_DESC_COL_WIDTH = 380

  def initialize(sale)
    super()
    @sale = sale
    @member = sale.member
    # Recuperiamo il nome prodotto. Adattalo se la tua struttura è diversa.
    @product_name = @sale.product&.name || "Servizio Palestra"

    header_section
    recipient_section
    body_section
    footer_legal_section
  end

  def header_section
    # --- DESTRA (Dati Ricevuta) ---
    float do
      bounding_box([ HEADER_RIGHT_X, cursor ], width: HEADER_RIGHT_WIDTH) do
        # Usa l'ID se receipt_code non esiste ancora
        code = @sale.respond_to?(:receipt_code) ? @sale.receipt_code : "##{@sale.id}"
        text "RICEVUTA N. #{code}", size: FONT_SIZE_L, style: :bold, align: :right, color: COLOR_ACCENT

        text "Data: #{I18n.l(@sale.sold_on)}", size: FONT_SIZE_M, align: :right
        move_down GAP_XS
        text "Pagamento: #{@sale.payment_method.humanize}", size: FONT_SIZE_S, align: :right
      end
    end

    # --- SINISTRA (Dati Palestra - con FALLBACK) ---
    # Se GymProfile esiste usa quello, altrimenti usa stringhe statiche
    gym_name = defined?(GymProfile) ? GymProfile.name : "NOME PALESTRA ASD"
    gym_address = defined?(GymProfile) ? GymProfile.address_line_1 : "Via Esempio, 123 - Città"
    gym_vat = defined?(GymProfile) ? GymProfile.vat_number : "00000000000"

    span(HEADER_LEFT_WIDTH, position: :left) do
      text gym_name, size: FONT_SIZE_XL, style: :bold, color: COLOR_PRIMARY
      text "Associazione Sportiva Dilettantistica", size: FONT_SIZE_S, color: COLOR_SECONDARY

      move_down GAP_S
      text gym_address, size: FONT_SIZE_S, color: COLOR_PRIMARY

      move_down 2
      # text "Tel: ... | Email: ...", size: FONT_SIZE_S, color: COLOR_PRIMARY # Decommenta se vuoi

      move_down 2
      text "C.F./P.IVA: #{gym_vat}", size: FONT_SIZE_S, style: :bold, color: COLOR_PRIMARY
    end

    move_down GAP_M
    draw_divider
    move_down GAP_M
  end

  def recipient_section
    text "Rilasciata a:", size: FONT_SIZE_XS, color: COLOR_SECONDARY, style: :bold, transform: :uppercase

    bounding_box([ 0, cursor ], width: RECIPIENT_BOX_WIDTH) do
      text @member.full_name, size: FONT_SIZE_L, style: :bold
      move_down GAP_XS

      if @member.fiscal_code.present?
        text "C.F. #{@member.fiscal_code.upcase}", size: FONT_SIZE_M, style: :bold
      else
        text "C.F. Non disponibile", size: FONT_SIZE_M, style: :italic, color: COLOR_SECONDARY
      end
    end

    move_down GAP_M
  end

  def body_section
    text "CAUSALE VERSAMENTO", size: FONT_SIZE_XS, style: :bold, color: COLOR_SECONDARY
    move_down GAP_XS

    description = "Contributo: #{@product_name}"

    # Se è un abbonamento, mostriamo le date
    if @sale.subscription
       description += "\nValidità: #{I18n.l(@sale.subscription.start_date)} - #{I18n.l(@sale.subscription.end_date)}"
    end

    data = [
      [ "DESCRIZIONE", "IMPORTO" ],
      [ description, format_currency(@sale.amount) ], # Attenzione: amount (o total_amount)
      [ "TOTALE", format_currency(@sale.amount) ]
    ]

    table(data, width: bounds.width) do
      # Header
      row(0).font_style = :bold
      row(0).size = FONT_SIZE_XS
      row(0).text_color = COLOR_SECONDARY
      row(0).background_color = COLOR_BG_HEADER
      row(0).borders = [ :bottom ]
      row(0).border_color = COLOR_LINE

      # Body
      cells.padding = [ GAP_S, GAP_XS ]
      cells.borders = [ :bottom ]
      cells.border_width = 0.5
      cells.border_color = COLOR_LINE

      # Footer (Totale)
      row(-1).font_style = :bold
      row(-1).size = FONT_SIZE_L
      row(-1).background_color = "FFFFFF"
      row(-1).borders = []
      row(-1).padding_top = GAP_M

      column(0).width = TABLE_DESC_COL_WIDTH
      column(1).align = :right
    end
  end

  def footer_legal_section
    footer_height = 60
    bounding_box([ bounds.left, bounds.bottom + footer_height ], width: bounds.width, height: footer_height) do
      text "NOTE FISCALI", size: FONT_SIZE_XS, style: :bold, color: COLOR_PRIMARY
      move_down 3
      legal_text = "Operazione effettuata in conformità all'art. 148 del T.U.I.R. e art. 4 del D.P.R. 633/72.\nSomma versata a titolo di quota associativa o corrispettivo specifico."
      text legal_text, size: FONT_SIZE_XS, color: COLOR_SECONDARY, align: :justify, leading: 1
    end
  end
end
