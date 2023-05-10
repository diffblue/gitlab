# frozen_string_literal: true

devise_scope :user do
  get '/users/auth/kerberos/negotiate' => 'omniauth_kerberos#negotiate'
end

scope :users, module: :users do
  resource :identity_verification, controller: :identity_verification, only: :show do
    post :verify_email_code
    post :resend_email_code
    post :send_phone_verification_code
    post :verify_phone_verification_code
    post :verify_arkose_labs_session
    get :arkose_labs_challenge
    get :verify_credit_card
    get :success
  end
end

scope(constraints: { username: Gitlab::PathRegex.root_namespace_route_regex }) do
  scope(path: 'users/:username', as: :user, controller: :users) do
    get :available_project_templates
    get :available_group_templates
  end
end
