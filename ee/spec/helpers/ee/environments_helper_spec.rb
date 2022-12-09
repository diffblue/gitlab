# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentsHelper do
  let_it_be_with_refind(:environment) { create(:environment) }
  let_it_be_with_refind(:deployment) { create(:deployment, :blocked, project: project, environment: environment) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { environment.project }

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

  describe '#deployment_approval_data' do
    subject { helper.deployment_approval_data(deployment) }

    before do
      stub_licensed_features(protected_environments: true)

      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?)
        .with(user, :approve_deployment, deployment)
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
                has_approval_rules
                project_id
                project_path
                name
                tier)

      expect(subject.keys).to match_array(keys)
    end
  end

  describe '#show_deployment_approval?' do
    subject { helper.show_deployment_approval?(deployment) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'can read deployment' do
      before do
        allow(helper).to receive(:can?)
          .with(user, :read_deployment, deployment)
          .and_return(true)
      end

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'cannot read deployment' do
      before do
        allow(helper).to receive(:can?)
          .with(user, :read_deployment, deployment)
          .and_return(false)
      end

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe '#can_approve_deployment?' do
    let_it_be(:protected_environment) do
      create(:protected_environment, name: environment.name, project: project, authorize_user_to_deploy: user)
    end

    subject { helper.can_approve_deployment?(deployment) }

    before do
      stub_licensed_features(protected_environments: true)

      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'when environment has a unified approval setting' do
      context 'user has access' do
        before do
          project.add_developer(user)
        end

        context 'with required approvals count = 0' do
          it 'returns false' do
            expect(subject).to be(false)
          end
        end

        context 'with required approvals count > 0' do
          before do
            protected_environment.update!(required_approval_count: 2)
          end

          it 'returns true' do
            expect(subject).to be(true)
          end
        end
      end

      context 'user does not have access' do
        before do
          project.add_reporter(user)
        end

        it 'returns false' do
          expect(subject).to be(false)
        end
      end
    end

    context 'when environment has multiple approval rules' do
      let_it_be(:qa_group) { create(:group, name: 'QA') }
      let_it_be(:security_group) { create(:group, name: 'Security') }

      before do
        create(:protected_environment_approval_rule,
          group_id: qa_group.id,
          protected_environment: protected_environment)

        create(:protected_environment_approval_rule,
          group_id: security_group.id,
          protected_environment: protected_environment)
      end

      context 'user has access' do
        before do
          qa_group.add_developer(user)
          project.add_developer(user)
        end

        it 'returns true' do
          expect(subject).to be(true)
        end
      end

      context 'user does not have access' do
        context 'with no matching approval rules' do
          before do
            project.add_reporter(user)
          end

          it 'returns false' do
            expect(subject).to be(false)
          end
        end

        context 'when cannot read deployment' do
          before do
            qa_group.add_developer(user)
            project.add_guest(user)
          end

          it 'returns false' do
            expect(subject).to be(false)
          end
        end
      end
    end
  end
end
