# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::CreateService, '#execute', feature_category: :environment_management do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }

  let(:params) do
    attributes_for(:protected_environment,
                   deploy_access_levels_attributes: [{ access_level: maintainer_access }])
  end

  subject { described_class.new(container: project, current_user: user, params: params).execute }

  context 'with valid params' do
    it { is_expected.to be_truthy }

    it 'creates a record on ProtectedEnvironment' do
      expect { subject }.to change(ProtectedEnvironment, :count).by(1)
    end

    it 'creates a record on ProtectedEnvironment record' do
      expect { subject }.to change(ProtectedEnvironments::DeployAccessLevel, :count).by(1)
    end

    it 'stores and logs the audit event' do
      subject

      protected_environment = project.protected_environments.last

      audit_context = {
        name: 'environment_protected',
        author: user,
        scope: project,
        target: protected_environment,
        message: "Protected an environment: #{protected_environment.name}"
      }

      allow(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)
    end
  end

  context 'with invalid params' do
    let(:maintainer_access) { 0 }

    it 'returns a non-persisted Protected Environment record' do
      expect(subject.persisted?).to be_falsy
    end

    it 'does not store or log the audit event' do
      expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

      subject
    end

    context 'multiple deploy access levels' do
      let(:params) do
        attributes_for(:protected_environment,
                       deploy_access_levels_attributes: [{ group_id: group.id, user_id: user_to_add.id }])
      end

      it_behaves_like 'invalid multiple deployment access levels' do
        it 'does not create protected environment' do
          expect { subject }.not_to change(ProtectedEnvironment, :count)
        end
      end
    end
  end

  context 'deploy access level by group' do
    let(:params) do
      attributes_for(:protected_environment,
                     deploy_access_levels_attributes: [{ group_id: group.id }])
    end

    it_behaves_like 'invalid protected environment group' do
      it 'does not create protected environment' do
        expect { subject }.not_to change(ProtectedEnvironment, :count)
      end
    end

    it_behaves_like 'valid protected environment group' do
      it 'creates protected environment' do
        expect { subject }.to change(ProtectedEnvironment, :count).by(1)
      end
    end
  end

  context 'deploy access level by user' do
    let(:params) do
      attributes_for(:protected_environment,
                     deploy_access_levels_attributes: [{ user_id: user_to_add.id }])
    end

    it_behaves_like 'invalid protected environment user' do
      it 'does not create protected environment' do
        expect { subject }.not_to change(ProtectedEnvironment, :count)
      end
    end

    it_behaves_like 'valid protected environment user' do
      it 'creates protected environment' do
        expect { subject }.to change(ProtectedEnvironment, :count).by(1)
      end
    end
  end
end
