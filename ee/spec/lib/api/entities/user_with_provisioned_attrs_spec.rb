# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::UserWithProvisionedAttrs, feature_category: :system_access do
  let(:group) { create(:group) }
  let(:user) { create(:user, provisioned_by_group: group) }
  let(:options) { {} }

  subject(:entity) { described_class.new(user, options).as_json }

  it 'does not include email address' do
    expect(entity.keys).not_to include(:email)
  end

  context 'when the current user can admin the provisioned user' do
    let(:current_user) { create(:user) }
    let(:options) { { current_user: current_user } }

    before do
      group.add_owner(current_user)
    end

    it 'includes the email address' do
      expect(entity[:email]).to eq(user.email)
    end
  end
end
