Rails.application.routes.draw do
  # ============================================================================
  # 1. AUTHENTICATION
  # ============================================================================
  resource :session
  resources :passwords, param: :token

  # ============================================================================
  # 2. ANAGRAFICA (Registry)
  # ============================================================================
  resources :members do
    resources :subscriptions, only: [ :index ], module: :members
    resources :access_logs,   only: [ :index ], module: :members
    resources :sales,         only: [ :index ], module: :members
  end

  resources :users
  namespace :preferences do
    resource :theme, only: [ :show, :update ]
    resource :language, only: [ :update ]
  end

  # ============================================================================
  # 3. CATALOGO (Catalog)
  # ============================================================================
  resources :disciplines
  resources :products

  # ============================================================================
  # 4. AMMINISTRAZIONE & VENDITE (Accounting)
  # ============================================================================
  resources :sales, only: [ :index, :new, :create, :show, :destroy ]

  resources :subscriptions, only: [ :index, :edit, :update ]
  resources :receipt_counters

  # ============================================================================
  # 5. ACCESSI (Access Control)
  # ============================================================================
  resources :access_logs, only: [ :index, :new, :create ]

  # ============================================================================
  # 6. REPORTING & UTILITY
  # ============================================================================
  resources :reports, only: [ :index, :show ], param: :report_type
  resources :feedbacks, only: [ :new, :create ]

  # ============================================================================
  # ROOT & SYSTEM
  # ============================================================================
  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboard#index"
end
