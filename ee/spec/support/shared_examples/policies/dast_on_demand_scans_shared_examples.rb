# frozen_string_literal: true

RSpec.shared_examples 'a dast on-demand scan policy' do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  subject { described_class.new(user, record) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  describe 'dast on-demand policies' do
    let(:policies) { [:create_on_demand_dast_scan, :edit_on_demand_dast_scan, :read_on_demand_dast_scan] }

    context 'when a user does not have access to the project' do
      it { is_expected.to be_disallowed(*policies) }
    end

    context 'when the user is a guest' do
      before do
        project.add_guest(user)
      end

      it { is_expected.to be_disallowed(*policies) }
    end

    context 'when the user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it { is_expected.to be_disallowed(*policies) }
    end

    context 'when the user is a developer' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be_allowed(*policies) }
    end

    context 'when the user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { is_expected.to be_allowed(*policies) }
    end

    context 'when the user is an owner' do
      before do
        group.add_owner(user)
      end

      it { is_expected.to be_allowed(*policies) }
    end

    context 'when the user is an auditor' do
      let(:user) { create(:user, :auditor) }
      let(:disallowed_policies) { [:create_on_demand_dast_scan, :edit_on_demand_dast_scan] }
      let(:allowed_policies) { [:read_on_demand_dast_scan] }

      it { is_expected.to be_disallowed(*disallowed_policies) }
      it { is_expected.to be_allowed(*allowed_policies) }
    end

    context 'when the user is allowed' do
      before do
        project.add_developer(user)
      end

      context 'when on demand scan licensed feature is not available' do
        let(:project) { create(:project, group: group) } # allows license stub to work correctly

        before do
          stub_licensed_features(security_on_demand_scans: false)
        end

        it { is_expected.to be_disallowed(*policies) }
      end
    end
  end
end
