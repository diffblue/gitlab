# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Policies::GroupPolicy, feature_category: :package_registry do
  include_context 'GroupPolicy context'

  subject { described_class.new(current_user, group.packages_policy_subject) }

  context 'with ip restriction' do
    let(:current_user) { maintainer }

    before do
      allow(Gitlab::IpAddressState).to receive(:current).and_return('192.168.0.2')
      stub_licensed_features(group_ip_restriction: true)
      stub_config(dependency_proxy: { enabled: true })
    end

    context 'without restriction' do
      it { is_expected.to be_allowed(:read_package) }
      it { is_expected.to be_allowed(:create_package) }
      it { is_expected.to be_allowed(:destroy_package) }
      it { is_expected.to be_allowed(:admin_package) }
    end

    context 'with restriction' do
      before do
        create(:ip_restriction, group: group, range: range)
      end

      context 'with address is within the range' do
        let(:range) { '192.168.0.0/24' }

        it { is_expected.to be_allowed(:read_package) }
        it { is_expected.to be_allowed(:create_package) }
        it { is_expected.to be_allowed(:destroy_package) }
        it { is_expected.to be_allowed(:admin_package) }
      end

      context 'with address is outside the range' do
        let(:range) { '10.0.0.0/8' }

        context 'as maintainer' do
          it { is_expected.to be_disallowed(:read_package) }
          it { is_expected.to be_disallowed(:create_package) }
          it { is_expected.to be_disallowed(:destroy_package) }
          it { is_expected.to be_disallowed(:admin_package) }
          it { is_expected.to be_disallowed(:update_package) }
        end

        context 'as owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:read_package) }
          it { is_expected.to be_allowed(:create_package) }
          it { is_expected.to be_allowed(:destroy_package) }
          it { is_expected.to be_allowed(:admin_package) }
        end
      end
    end
  end
end
