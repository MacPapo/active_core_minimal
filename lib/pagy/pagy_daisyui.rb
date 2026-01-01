# frozen_string_literal: true

require "pagy/toolbox/helpers/support/wrap_series_nav"

class Pagy
  private
    def daisyui_series_nav(classes: "join", **)
      a_lambda = daisyui_a_lambda(**)
      html = %(<div class="#{classes}">#{daisyui_html_for(:previous, a_lambda)})
      series(**).each do |item|
        html << case item
        when Integer
          a_lambda.(item,
                    classes: "join-item btn")
        when String
          a_lambda.(item,
                    page_label(item),
                    classes: "join-item btn btn-active",
                    disabled: true)
        when :gap
          a_lambda.(:gap,
                    I18n.translate("pagy.gap"),
                    classes: "join-item btn btn-disabled",
                    disabled: true)
        else
          raise InternalError, "expected Integer, String or :gap; got #{item.inspect}"
        end
      end
      html << %(#{daisyui_html_for(:next, a_lambda)}</div>)
    end

    def daisyui_html_for(which, a_lambda)
      if send(which)
        a_lambda.(send(which),
                  I18n.translate("pagy.#{which}"),
                  classes: "join-item btn",
                  aria_label: I18n.translate("pagy.aria_label.#{which}"))
      else
        a_lambda.(which,
                  I18n.translate("pagy.#{which}"),
                  classes: "join-item btn btn-disabled",
                  disabled: true,
                  aria_label: I18n.translate("pagy.aria_label.#{which}"))
      end
    end

    def daisyui_a_lambda(anchor_string: nil, **)
      left, right = %(<a href="#{compose_page_url(PAGE_TOKEN, **)}"#{
                    %( #{anchor_string}) if anchor_string}).split(PAGE_TOKEN, 2)

      lambda do |page, text = page_label(page), classes: nil, aria_label: nil, disabled: false, aria_current: nil|
        if disabled
          attrs = []
          attrs << %( class="#{classes}") if classes
          attrs << %( aria-label="#{aria_label}") if aria_label
          attrs << %( aria-current="#{aria_current}") if aria_current

          return %(<span#{attrs.join}>#{text}</span>)
        end

        title = if (counts = @options[:counts])
                  count    = counts[page - 1]
                  classes  = classes ? "#{classes} empty-page" : "empty-page" if count.zero?
                  info_key = count.zero? ? "pagy.info_tag.no_items" : "pagy.info_tag.single_page"
                  %( title="#{I18n.translate(info_key, item_name: I18n.translate('pagy.item_name', count:), count:)}")
        end

        rel = case page
        when @previous then %( rel="prev")
        when @next     then %( rel="next")
        end

        %(#{left}#{page}#{right}#{title}#{
        %( class="#{classes}") if classes}#{rel}#{
        %( aria-label="#{aria_label}") if aria_label}#{
        %( aria-current="#{aria_current}") if aria_current}>#{text}</a>)
      end
    end
end
