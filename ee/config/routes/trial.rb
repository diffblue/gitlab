# frozen_string_literal: true

resources :trials, only: [:new] do
  collection do
    post :create_lead
    get :select
    post :apply
    put :extend_reactivate
  end
end
