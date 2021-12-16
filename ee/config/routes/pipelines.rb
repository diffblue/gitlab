# frozen_string_literal: true

resources :pipelines, only: [] do
  member do
    get :security
    get :licenses
    get :codequality_report
  end

  get 'validate_account', action: :validate_account, controller: 'pipelines/email_campaigns'
end
