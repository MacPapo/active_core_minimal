module FilterableActions
  extend ActiveSupport::Concern

  included do
    helper_method :current_filter_params
  end

  def filter_and_paginate(scope, filter_namespace: :query)
    model_class = scope.model

    @available_filters = model_class.available_filters
    @available_sorts   = model_class.available_sorts

    flat_params = extract_flat_params(model_class, filter_namespace)
    filtered_scope = scope.merge(model_class.apply_filters(flat_params))

    pagy(filtered_scope)
  end

  private
    def extract_flat_params(model_class, namespace)
      permitted_keys = model_class.available_filters.map { |f| f[:key] }
      namespace_params = params.fetch(namespace, {}).permit(permitted_keys)
      sort_params = params.permit(:sort, :direction)
      namespace_params.merge(sort_params)
    end

    def current_filter_params
      @_current_filter_params ||= params.fetch(:query, {}).to_unsafe_h
    end
end
