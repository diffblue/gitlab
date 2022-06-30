# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InstanceSecurityDashboardPolicy do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(security_dashboard: true)
  end

  subject { described_class.new(current_user, [user]) }

  describe 'read_instance_security_dashboard' do
    let(:abilities) { %i[read_instance_security_dashboard read_security_resource] }

    context 'when the user is not logged in' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(*abilities) }
    end

    context 'when the user is logged in' do
      it { is_expected.to be_allowed(*abilities) }
    end
  end

  describe 'create_vulnerability_export' do
    context 'when the user is not logged in' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:create_vulnerability_export) }
    end

    context 'when the user is logged in' do
      it { is_expected.to be_allowed(:create_vulnerability_export) }
    end
  end

  describe 'read_cluster' do
    context 'when the user is not logged in' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:read_cluster) }
    end

    context 'when the user is logged in' do
      it { is_expected.to be_allowed(:read_cluster) }
    end
  end
end
