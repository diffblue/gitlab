# frozen_string_literal: true

resource :profile, only: [] do
  scope module: :profiles do
    resources :usage_quotas, only: [:index]
    resources :billings, only: [:index]
  end
end
