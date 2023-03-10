# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GeoNodePolicy, feature_category: :geo_replication do
  let_it_be(:geo_node) { create(:geo_node) }

  subject(:policy) { described_class.new(current_user, geo_node) }

  context 'when the user is an admin' do
    let(:current_user) { create(:user, :admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it 'allows read_geo_node for any GeoNode' do
        expect(policy).to be_allowed(:read_geo_node)
      end
    end

    context 'when admin mode is disabled' do
      it 'disallows read_geo_node for any GeoNode' do
        expect(policy).to be_disallowed(:read_geo_node)
      end
    end
  end

  context 'when the user is not an admin' do
    let(:current_user) { create(:user) }

    it 'disallows read_geo_node for any GeoNode' do
      expect(policy).to be_disallowed(:read_geo_node)
    end
  end
end
