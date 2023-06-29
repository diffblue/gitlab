# frozen_string_literal: true

FactoryBot.define do
  factory :system_access_microsoft_application, class: 'SystemAccess::MicrosoftApplication' do
    namespace
    enabled { true }
    tenant_xid { generate(:token) }
    client_xid { generate(:token) }
    client_secret { generate(:token) }
  end
end
