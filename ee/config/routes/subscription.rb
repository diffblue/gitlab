# frozen_string_literal: true

resource :subscriptions, only: [:new, :create] do
  get :buy_minutes
  get :buy_storage
  get :payment_form
  get :payment_method
  post :validate_payment_method

  scope module: :subscriptions do
    resources :groups, only: [:edit, :update]
  end
end
