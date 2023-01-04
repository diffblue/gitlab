# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::DestroyService, '#execute', feature_category: :environment_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let!(:protected_environment) { create(:protected_environment, project: project) }
  let(:deploy_access_level) { protected_environment.deploy_access_levels.first }

  subject { described_class.new(container: project, current_user: user).execute(protected_environment) }

  context 'when the Protected Environment is deleted' do
    it { is_expected.to be_truthy }

    it 'deletes the requested ProtectedEnvironment' do
      expect do
        subject
      end.to change { ProtectedEnvironment.count }.from(1).to(0)
    end

    it 'deletes the related DeployAccessLevel' do
      expect do
        subject
      end.to change { ProtectedEnvironments::DeployAccessLevel.count }.from(1).to(0)
    end

    it 'stores and logs the audit event' do
      audit_context = {
        name: 'environment_unprotected',
        author: user,
        scope: project,
        target: protected_environment,
        message: "Unprotected an environment: #{protected_environment.name}"
      }

      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)

      subject
    end
  end

  context 'when the Protected Environment can not be deleted' do
    let(:protected_environment_double) { instance_double(ProtectedEnvironment) }

    before do
      allow(protected_environment_double).to receive(:destroy).and_return(protected_environment)
      allow(protected_environment).to receive(:tap).and_return(false)
    end

    it { is_expected.to be_falsy }

    it 'does not store or log the audit event' do
      expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

      subject
    end
  end
end
