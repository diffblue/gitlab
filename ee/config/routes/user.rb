# frozen_string_literal: true

devise_scope :user do
  get '/users/auth/kerberos_spnego/negotiate' => 'omniauth_kerberos_spnego#negotiate'
end

scope(constraints: { username: Gitlab::PathRegex.root_namespace_route_regex }) do
  scope(path: 'users/:username',
        as: :user,
        controller: :users) do
    get :available_project_templates
    get :available_group_templates
  end
end

namespace :users do
  resource :identity_verification, controller: :identity_verification, only: :show
end
