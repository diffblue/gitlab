# frozen_string_literal: true

resources :trials, only: [:new, :create] do
  collection do
    post :create_lead
    post :apply
  end
end

# Deprecated route, remove with https://gitlab.com/gitlab-org/gitlab/-/issues/393969
get 'trials/select', to: redirect('-/trials/new?step=trial')
