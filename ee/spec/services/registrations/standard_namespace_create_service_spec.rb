# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::StandardNamespaceCreateService, :aggregate_failures, feature_category: :onboarding do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let(:extra_params) { {} }
    let(:group_params) do
      {
        name: 'Group name',
        path: 'group-path',
        visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s
      }
    end

    let(:project_params) do
      {
        name: 'New project',
        path: 'project-path',
        visibility_level: Gitlab::VisibilityLevel::PRIVATE,
        initialize_with_readme: 'true'
      }
    end

    let(:params) do
      ActionController::Parameters.new({ group: group_params, project: project_params }.merge(extra_params))
    end

    before_all do
      group.add_owner(user)
    end

    subject(:execute) { described_class.new(user, params).execute }

    context 'when group and project can be created' do
      it 'creates a group with onboarding and project' do
        expect do
          expect(execute).to be_success
        end
          .to change { Group.count }
                .by(1).and change { Project.count }.by(1).and change { Onboarding::Progress.count }.by(1)
      end

      it 'passes create_event: true to the Groups::CreateService' do
        added_params = { create_event: true, setup_for_company: nil }

        expect(Groups::CreateService).to receive(:new)
                                           .with(user, ActionController::Parameters
                                                         .new(group_params.merge(added_params)).permit!)
                                           .and_call_original

        expect(execute).to be_success
      end

      it 'allows for the project to be initialized with a README' do
        expect(::Projects::CreateService).to receive(:new).with(
          user,
          an_object_satisfying { |permitted| permitted.include?(:initialize_with_readme) }
        ).and_call_original

        expect(execute).to be_success
      end

      it 'tracks group and project creation events' do
        allow_next_instance_of(::Projects::CreateService) do |service|
          allow(service).to receive(:after_create_actions)
        end

        expect(execute).to be_success

        expect_snowplow_event(
          category: described_class.name,
          action: 'create_group',
          namespace: an_instance_of(Group),
          user: user
        )
        expect_snowplow_event(
          category: described_class.name,
          action: 'create_project',
          namespace: an_instance_of(Group),
          user: user
        )
      end

      it 'tracks automatic_trial_registration assignment event with group information', :experiment do
        expect(experiment(:automatic_trial_registration)).to track(:assignment, namespace: an_instance_of(Group))
          .on_next_instance
          .with_context(actor: user)

        expect(execute).to be_success
      end

      it 'does not attempt to create a trial' do
        expect(GitlabSubscriptions::Trials::ApplyTrialWorker).not_to receive(:perform_async)

        expect(execute).to be_success
      end
    end

    context 'when the group cannot be created' do
      let(:group_params) { { name: '', path: '' } }

      it 'does not create a group' do
        expect do
          expect(execute).to be_error
        end.not_to change { Group.count }
        expect(execute.payload[:group].errors).not_to be_blank
      end

      it 'does not track events for group or project creation' do
        expect(execute).to be_error

        expect_no_snowplow_event(category: described_class.name, action: 'create_group')
        expect_no_snowplow_event(category: described_class.name, action: 'create_project')
      end

      it 'the project is not disregarded completely' do
        expect(execute).to be_error

        expect(execute.payload[:project].name).to eq('New project')
      end

      context 'with trial concerns' do
        let(:extra_params) { { trial_onboarding_flow: 'true' } }

        it 'does not attempt to create a trial' do
          expect(GitlabSubscriptions::Trials::ApplyTrialWorker).not_to receive(:perform_async)

          expect(execute).to be_error
        end
      end
    end

    context 'when group can be created but not the project' do
      let(:project_params) { { name: '', path: '', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

      it 'does not create a project' do
        expect do
          expect(execute).to be_error
        end.to change { Group.count }.and change { Onboarding::Progress.count }.and change { Project.count }.by(0)
        expect(execute.payload[:project].errors).not_to be_blank
      end

      it 'selectively tracks events for group and project creation' do
        expect(execute).to be_error

        expect_snowplow_event(
          category: described_class.name,
          action: 'create_group',
          namespace: an_instance_of(Group),
          user: user
        )
        expect_no_snowplow_event(category: described_class.name, action: 'create_project')
      end
    end

    context 'when a group already exists and projects needs to be created' do
      let(:group_params) { { id: group.id } }

      it 'creates a project and not another group' do
        expect do
          expect(execute).to be_success
        end.to change { Group.count }.by(0).and change { Onboarding::Progress.count }.by(0).and change { Project.count }
      end

      it 'selectively tracks events group and project creation' do
        # stub out other tracking calls because it breaks our other tracking assertions
        allow_next_instance_of(::Projects::CreateService) do |service|
          allow(service).to receive(:after_create_actions)
        end

        expect(execute).to be_success

        expect_no_snowplow_event(category: described_class.name, action: 'create_group')
        expect_snowplow_event(
          category: described_class.name,
          action: 'create_project',
          namespace: an_instance_of(Group),
          user: user
        )
      end
    end

    context 'with applying for a trial' do
      let(:extra_params) do
        { trial_onboarding_flow: 'true', glm_source: 'about.gitlab.com', glm_content: 'content', trial: 'true' }
      end

      let(:trial_user_information) do
        ActionController::Parameters.new(
          {
            glm_source: 'about.gitlab.com',
            glm_content: 'content',
            namespace_id: group.id,
            gitlab_com_trial: true,
            sync_to_gl: true
          }
        )
      end

      before do
        allow_next_instance_of(::Groups::CreateService) do |service|
          allow(service).to receive(:execute).and_return(group)
        end
      end

      it 'applies a trial' do
        expect(GitlabSubscriptions::Trials::ApplyTrialWorker).to receive(:perform_async)
                                                                   .with(user.id, trial_user_information)
                                                                   .and_call_original

        expect(execute).to be_success
      end

      context 'when a group already exists applying a trial is not attempted' do
        let(:group_params) { { id: group.id } }

        it 'creates a project and not another group or trial' do
          expect(GitlabSubscriptions::Trials::ApplyTrialWorker).not_to receive(:perform_async)

          expect do
            expect(execute).to be_success
          end.to change { Group.count }.by(0).and change { Project.count }
        end
      end

      context 'when automatic_trial_registration experiment is enabled' do
        subject(:service) { described_class.new(user, params) }

        it 'does not track experiment assignment event' do
          stub_experiments(automatic_trial_registration: true)

          expect(service).not_to receive(:experiment).with(:automatic_trial_registration, actor: user)

          expect(service.execute).to be_success
        end
      end
    end
  end
end
