# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentsHelper do
  let(:environment) { create(:environment) }
  let(:project) { environment.project }
  let(:user) { create(:user) }

  describe '#environment_logs_data' do
    subject { helper.environment_logs_data(project, environment) }

    it 'returns environment parameters data' do
      expect(subject).to include(
        "environment_name": environment.name,
        "environments_path": api_v4_projects_environments_path(id: project.id)
      )
    end

    it 'returns parameters for forming the pod logs API URL' do
      expect(subject).to include(
        "environment_id": environment.id
      )
    end
  end

  describe 'deployment_approval_data' do
    let(:deployment) { create(:deployment, :blocked, project: project, environment: environment) }

    subject { helper.deployment_approval_data(deployment) }

    before do
      stub_licensed_features(protected_environments: true)
      create(:protected_environment, name: environment.name, project: project, required_approval_count: 3)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?)
        .with(user, :update_deployment, deployment)
        .and_return(true)
    end

    it 'provides data for a deployment approval' do
      keys = %i(pending_approval_count
                iid
                id
                required_approval_count
                can_approve_deployment
                deployable_name
                approvals
                project_id
                name
                tier)

      expect(subject.keys).to match_array(keys)
    end
  end

  describe 'show_deployment_approval?' do
    let(:deployment) { create(:deployment, :blocked, project: project, environment: environment) }

    subject { helper.show_deployment_approval?(deployment) }

    before do
      stub_licensed_features(protected_environments: true)
    end

    context 'with a required approval count' do
      before do
        create(:protected_environment, name: environment.name, project: project, required_approval_count: 3)
        allow(helper).to receive(:current_user).and_return(user)
      end

      context 'user has access' do
        before do
          allow(helper).to receive(:can?)
            .with(user, :update_deployment, deployment)
            .and_return(true)
        end

        it 'returns true' do
          expect(subject).to be(true)
        end
      end

      context 'user does not have access' do
        before do
          allow(helper).to receive(:can?)
            .with(user, :update_deployment, deployment)
            .and_return(false)
        end

        it 'returns false' do
          expect(subject).to be(false)
        end
      end
    end

    context 'without a required approval count' do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:can?)
          .with(user, :update_deployment, deployment)
          .and_return(true)
      end

      it 'returns false' do
        expect(subject).to be(false)
      end
    end
  end
end
