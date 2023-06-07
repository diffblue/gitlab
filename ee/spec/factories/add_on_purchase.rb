# frozen_string_literal: true

FactoryBot.define do
  factory :add_on_purchase, class: 'GitlabSubscriptions::AddOnPurchase' do
    add_on
    namespace { association(:group) }
    quantity { 1 }
    expires_on { 1.year.from_now.to_date }
    purchase_xid { 'S-A00000001' }
  end
end
