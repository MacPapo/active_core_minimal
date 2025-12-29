module Filterable
  extend ActiveSupport::Concern

  class_methods do
    def available_filters
      []
    end

    def allowed_filter_keys
      keys = available_filters.map { |f| f[:key] }
      keys << :query unless keys.include?(:query)

      keys
    end

    def apply_filters(params)
      scope = all
      return scope if params.blank?

      # 1. Search Text (Standard)
      if params[:query].present? && respond_to?(:search_by_text)
        scope = scope.search_by_text(params[:query])
      end

      # 2. Dynamic Filters
      available_filters.each do |filter_config|
        key = filter_config[:key]
        value = params[key]

        # Saltiamo :query qui perché gestito sopra (o se vuoi gestirlo dinamicamente, rimuovi il blocco if sopra)
        next if key == :query

        scope_name = "filter_by_#{key}"
        if value.present? && respond_to?(scope_name)
          scope = scope.send(scope_name, value)
        end
      end

      scope
    end
  end
end
