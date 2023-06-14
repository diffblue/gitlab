# frozen_string_literal: true

FactoryBot.define do
  factory :gitlab_subscription_add_on_purchase, class: 'GitlabSubscriptions::AddOnPurchase' do
    add_on { association(:gitlab_subscription_add_on) }
    namespace { association(:group) }
    quantity { 1 }
    expires_on { 1.year.from_now.to_date }
    purchase_xid { SecureRandom.hex(16) }
  end
end
