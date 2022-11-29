# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Policies::ProjectPolicy, feature_category: :package_registry do
  include_context 'ProjectPolicy context'

  let(:project) { public_project }

  subject { described_class.new(current_user, project.packages_policy_subject) }

  context 'with ip restriction' do
    let(:current_user) { create(:admin) }

    let_it_be_with_reload(:group) { create(:group, :public) }
    let_it_be_with_reload(:project) { create(:project, group: group) }

    before do
      allow(Gitlab::IpAddressState).to receive(:current).and_return('192.168.0.2')
      stub_licensed_features(group_ip_restriction: true)
      group.add_maintainer(current_user)
    end

    context 'with group without restriction' do
      it { is_expected.to be_allowed(:read_package) }
      it { is_expected.to be_allowed(:create_package) }
      it { is_expected.to be_allowed(:destroy_package) }
      it { is_expected.to be_allowed(:admin_package) }
    end

    context 'with group with restriction' do
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

        it { is_expected.to be_disallowed(:read_package) }
        it { is_expected.to be_disallowed(:create_package) }
        it { is_expected.to be_disallowed(:destroy_package) }
        it { is_expected.to be_disallowed(:admin_package) }
        it { is_expected.to be_disallowed(:update_package) }

        context 'with admin enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(:read_package) }
          it { is_expected.to be_allowed(:create_package) }
          it { is_expected.to be_allowed(:destroy_package) }
          it { is_expected.to be_allowed(:admin_package) }
        end

        context 'with admin disabled' do
          it { is_expected.to be_disallowed(:read_package) }
          it { is_expected.to be_disallowed(:create_package) }
          it { is_expected.to be_disallowed(:destroy_package) }
          it { is_expected.to be_disallowed(:admin_package) }
        end

        context 'with auditor' do
          let(:current_user) { create(:user, :auditor) }

          it { is_expected.to be_allowed(:read_package) }
          it { is_expected.to be_allowed(:create_package) }
          it { is_expected.to be_allowed(:destroy_package) }
          it { is_expected.to be_allowed(:admin_package) }
        end
      end
    end
  end
end
