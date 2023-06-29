# frozen_string_literal: true

FactoryBot.define do
  factory :system_access_microsoft_graph_access_token, class: 'SystemAccess::MicrosoftGraphAccessToken' do
    system_access_microsoft_application
    token { generate(:token) }
    expires_in { 3600 }
  end
end
