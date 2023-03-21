# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::UpdateService, '#execute' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }
  let(:protected_environment) { create(:protected_environment, project: project) }
  let(:deploy_access_level) { protected_environment.deploy_access_levels.first }

  let(:params) do
    {
      deploy_access_levels_attributes: [
        { id: deploy_access_level.id, access_level: Gitlab::Access::DEVELOPER, user_id: nil },
        { access_level: maintainer_access }
      ]
    }
  end

  subject { described_class.new(container: project, current_user: user, params: params).execute(protected_environment) }

  before do
    deploy_access_level
  end

  context 'with valid params' do
    it { is_expected.to be_truthy }

    it 'updates the deploy access levels' do
      expect do
        subject
      end.to change { ProtectedEnvironments::DeployAccessLevel.count }.from(1).to(2)
    end
  end

  context 'with invalid params' do
    let(:maintainer_access) { 0 }

    it { is_expected.to be_falsy }

    it 'does not update the deploy access levels' do
      expect do
        subject
      end.not_to change { ProtectedEnvironments::DeployAccessLevel.count }
    end

    context 'multiple deploy access levels' do
      let(:params) do
        attributes_for(:protected_environment,
                       deploy_access_levels_attributes: [{ group_id: group.id, user_id: user_to_add.id }])
      end

      it_behaves_like 'invalid multiple deployment access levels'
    end
  end

  context 'deploy access level by group' do
    let(:params) { { deploy_access_levels_attributes: [{ group_id: group.id }] } }

    it_behaves_like 'invalid protected environment group'

    it_behaves_like 'valid protected environment group'
  end

  context 'deploy access level by user' do
    let(:params) do
      attributes_for(:protected_environment,
                     deploy_access_levels_attributes: [{ user_id: user_to_add.id }])
    end

    it_behaves_like 'invalid protected environment user'

    it_behaves_like 'valid protected environment user'
  end
end
