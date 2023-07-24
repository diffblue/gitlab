# frozen_string_literal: true

namespace :phone_verification do
  post 'telesign_callback', to: 'telesign_callbacks#notify'
end
