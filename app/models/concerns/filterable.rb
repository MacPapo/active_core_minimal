module Filterable
  extend ActiveSupport::Concern

  class_methods do
    def available_filters
      []
    end

    def available_sorts
      []
    end

    def default_sort_key
      :created_at
    end

    def default_sort_direction
      :desc
    end

    def apply_filters(params)
      scope = all
      return scope if params.nil?

      if params[:query].present? && respond_to?(:search_by_text)
        scope = scope.search_by_text(params[:query])
      end

      available_filters.each do |filter_config|
        key = filter_config[:key]
        value = params[key]

        next if key == :query
        next if value.blank?

        scope_name = "filter_by_#{key}"
        if respond_to?(scope_name)
          scope = scope.send(scope_name, value)
        end
      end

      scope = apply_sorting(scope, params)

      scope
    end

    def apply_sorting(scope, params)
      sort_key = params[:sort].presence || default_sort_key
      direction = params[:direction] == "desc" ? :desc : :asc

      allowed_keys = available_sorts.map { |s| s[:key].to_s }

      unless allowed_keys.include?(sort_key.to_s)
        sort_key = default_sort_key
        direction = default_sort_direction
      end

      scope_name = "sort_by_#{sort_key}"
      if respond_to?(scope_name)
        return scope.send(scope_name, direction)
      end

      if column_names.include?(sort_key.to_s)
        return scope.order(sort_key => direction)
      end

      scope
    end
  end
end
