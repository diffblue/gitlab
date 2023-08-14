# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::API::Entities::GitlabSubscriptions::AddOnPurchase, feature_category: :saas_provisioning do
  it 'contains the correct attributes', :aggregate_failures do
    add_on_purchase = build(:gitlab_subscription_add_on_purchase)

    entity = described_class.new(add_on_purchase).as_json

    expect(entity[:namespace_id]).to eq add_on_purchase.namespace_id
    expect(entity[:namespace_name]).to eq add_on_purchase.namespace.name
    expect(entity[:add_on]).to eq add_on_purchase.add_on.name.titleize
    expect(entity[:quantity]).to eq add_on_purchase.quantity
    expect(entity[:expires_on]).to eq add_on_purchase.expires_on
    expect(entity[:purchase_xid]).to eq add_on_purchase.purchase_xid
  end
end
