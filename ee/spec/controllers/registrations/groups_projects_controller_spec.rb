# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::GroupsProjectsController, :experiment do
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  describe 'GET #new' do
    it_behaves_like "Registrations::GroupsController GET #new"

    context 'not shared behavior' do
      subject { get :new }

      before do
        allow(::Gitlab).to receive(:dev_env_or_com?).and_return(true)
        sign_in(user)
      end

      it 'builds a project object' do
        subject

        expect(assigns(:project)).to be_a_new(Project)
      end

      it 'tracks an event for the combined_registration experiment' do
        expect(experiment(:combined_registration)).to track(:view_new_group_action).on_next_instance

        subject
      end

      it 'publishes the required verification experiment to the database' do
        expect_next_instance_of(RequireVerificationForNamespaceCreationExperiment) do |experiment|
          expect(experiment).to receive(:publish_to_database)
        end

        subject
      end
    end
  end

  shared_context 'records a conversion event' do
    let_it_be(:user_created_at) { RequireVerificationForNamespaceCreationExperiment::EXPERIMENT_START_DATE + 1.hour }
    let_it_be(:user) { create(:user, created_at: user_created_at) }
    let_it_be(:experiment) { create(:experiment, name: :require_verification_for_namespace_creation) }
    let_it_be(:experiment_subject) { create(:experiment_subject, experiment: experiment, user: user) }

    before do
      stub_experiments(require_verification_for_namespace_creation: true)
    end

    it 'records a conversion event for the required verification experiment' do
      expect { subject }.to change { experiment_subject.reload.converted_at }.from(nil)
        .and change { experiment_subject.context }.to include('namespace_id')
    end
  end

  describe 'POST #create' do
    subject(:post_create) { post :create, params: params }

    let(:params) { { group: group_params, project: project_params }.merge(extra_params) }
    let(:extra_params) { {} }
    let(:group_params) { { name: 'Group name', path: 'group-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s, setup_for_company: setup_for_company } }
    let(:project_params) { { name: 'New project', path: 'project-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }
    let(:dev_env_or_com) { true }
    let(:setup_for_company) { nil }
    let(:combined_registration?) { true }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
        allow(::Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)
      end

      it_behaves_like 'hides email confirmation warning'

      it_behaves_like 'records a conversion event'

      context 'when group and project can be created' do
        it 'creates a group' do
          expect { post_create }.to change { Group.count }.by(1)
        end

        it 'passes create_event: true to the Groups::CreateService' do
          expect(Groups::CreateService).to receive(:new).with(user, ActionController::Parameters.new(group_params.merge(create_event: true)).permit!).and_call_original

          post_create
        end

        it 'tracks create events for the combined_registration experiment' do
          allow_next_instance_of(::Projects::CreateService) do |service|
            allow(service).to receive(:after_create_actions)
          end

          wrapped_experiment(experiment(:combined_registration)) do |e|
            expect(e).to receive(:track).with(:create_group, namespace: an_instance_of(Group))
            expect(e).to receive(:track).with(:create_project, namespace: an_instance_of(Group))
          end

          post_create
        end
      end

      context 'when there is no suggested path based from the name' do
        let(:group_params) { { name: '⛄⛄⛄', path: '' } }

        it 'creates a group' do
          expect { subject }.to change { Group.count }.by(1)
        end
      end

      context 'when the group cannot be created' do
        let(:group_params) { { name: '', path: '' } }

        it 'does not create a group', :aggregate_failures do
          expect { post_create }.not_to change { Group.count }
          expect(assigns(:group).errors).not_to be_blank
        end

        it 'does not tracks events for the combined_registration experiment' do
          wrapped_experiment(experiment(:combined_registration)) do |e|
            expect(e).not_to receive(:track).with(:create_group)
            expect(e).not_to receive(:track).with(:create_project)
          end

          post_create
        end

        it 'the project is not disgarded completely' do
          post_create

          expect(assigns(:project).name).to eq('New project')
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
        it { is_expected.to render_template(:new) }
      end

      context 'with signup onboarding not enabled' do
        let(:dev_env_or_com) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context "when group can be created but the project can't" do
        let(:project_params) { { name: '', path: '', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

        it 'does not create a project', :aggregate_failures do
          expect { post_create }.to change { Group.count }
          expect { post_create }.not_to change { Project.count }
          expect(assigns(:project).errors).not_to be_blank
        end

        it 'selectively tracks events for the combined_registration experiment' do
          wrapped_experiment(experiment(:combined_registration)) do |e|
            expect(e).to receive(:track).with(:create_group, namespace: an_instance_of(Group))
            expect(e).not_to receive(:track).with(:create_project)
          end

          post_create
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
        it { is_expected.to render_template(:new) }
      end

      context "when a group is already created but a project isn't" do
        before do
          group.add_owner(user)
        end

        let(:group_params) { { id: group.id } }

        it 'creates a project and not another group', :aggregate_failures do
          expect { post_create }.to change { Project.count }
          expect { post_create }.not_to change { Group.count }
        end

        it 'selectively tracks events for the combined_registration experiment' do
          allow_next_instance_of(::Projects::CreateService) do |service|
            allow(service).to receive(:after_create_actions)
          end

          wrapped_experiment(experiment(:combined_registration)) do |e|
            expect(e).not_to receive(:track).with(:create_group, namespace: an_instance_of(Group))
            expect(e).to receive(:track).with(:create_project, namespace: an_instance_of(Group))
          end

          post_create
        end
      end

      context 'it redirects' do
        let_it_be(:project) { create(:project) }

        let(:success_path) { continuous_onboarding_getting_started_users_sign_up_welcome_path(project_id: project.id) }

        before do
          allow_next_instance_of(::Projects::CreateService) do |service|
            allow(service).to receive(:execute).and_return(project)
          end
        end

        it { is_expected.to redirect_to(success_path) }

        context 'when the `registration_verification` experiment is enabled' do
          before do
            stub_experiments(registration_verification: :candidate)
          end

          it 'is expected to store the success path and redirect to the verification page' do
            expect(subject).to redirect_to(new_users_sign_up_verification_path(project_id: project.id))
            expect(controller.stored_location_for(:user)).to eq(success_path)
          end
        end

        context 'when setup_for_company is true' do
          let_it_be(:user) { create(:user, setup_for_company: true) }

          it 'is expected to store the success path and redirect to the new trial page' do
            expect(subject).to redirect_to(new_trial_path)
            expect(controller.stored_location_for(:user)).to eq(success_path)
          end

          context 'when the skip_trial param is set' do
            let(:extra_params) { { skip_trial: true } }

            it { is_expected.to redirect_to(success_path) }
          end

          context 'when the trial_onboarding_flow param is set' do
            let(:extra_params) { { trial_onboarding_flow: true } }

            before do
              allow_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
                allow(service).to receive(:execute).and_return({ success: true })
              end
            end

            it { is_expected.to redirect_to(success_path) }
          end
        end
      end

      context 'when in the trial onboarding flow' do
        let(:success) { true }
        let(:extra_params) do
          { trial_onboarding_flow: true, glm_source: 'about.gitlab.com', glm_content: 'content' }
        end

        let(:apply_trial_params) do
          {
            uid: user.id,
            trial_user: ActionController::Parameters.new(
              {
                glm_source: 'about.gitlab.com',
                glm_content: 'content',
                namespace_id: group.id,
                gitlab_com_trial: true,
                sync_to_gl: true
              }
            ).permit!
          }
        end

        before do
          allow_next_instance_of(::Groups::CreateService) do |service|
            allow(service).to receive(:execute).and_return(group)
          end

          expect_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
            expect(service).to receive(:execute).with(apply_trial_params).and_return({ success: success })
          end
        end

        it 'applies a trial' do
          post_create
        end

        context 'when failing to apply trial' do
          let(:success) { false }

          it { is_expected.to render_template(:new) }
        end
      end

      context 'learn gitlab project' do
        using RSpec::Parameterized::TableSyntax

        where(:trial, :project_name, :template) do
          false | 'Learn GitLab' | described_class::LEARN_GITLAB_ULTIMATE_TEMPLATE
          true  | 'Learn GitLab - Ultimate trial' | described_class::LEARN_GITLAB_ULTIMATE_TEMPLATE
        end

        with_them do
          let(:path) { Rails.root.join('vendor', 'project_templates', template) }
          let(:expected_arguments) { { namespace_id: group.id, file: handle, name: project_name } }
          let(:handle) { double }
          let(:group_params) { { id: group.id } }
          let(:extra_params) { { trial_onboarding_flow: trial } }

          before do
            group.add_owner(user)
            allow(File).to receive(:open).and_call_original
            expect(File).to receive(:open).with(path).and_yield(handle)
          end

          specify do
            expect_next(::Projects::GitlabProjectsImportService, user, expected_arguments)
              .to receive(:execute)

            subject
          end
        end
      end
    end
  end

  describe 'POST #import' do
    subject(:post_import) { post :import, params: params }

    let(:params) { { group: group_params, import_url: new_import_github_path } }
    let(:group_params) { { name: 'Group name', path: 'group-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s, setup_for_company: nil } }
    let(:dev_env_or_com) { true }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
        allow(::Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)
      end

      it_behaves_like 'hides email confirmation warning'

      it_behaves_like 'records a conversion event'

      context "when a group can't be created" do
        before do
          allow_next_instance_of(::Groups::CreateService) do |service|
            allow(service).to receive(:execute).and_return(Group.new)
          end
        end

        it "doesn't track for the combined_registration experiment" do
          expect(experiment(:combined_registration)).not_to track(:create_group)

          post_import
        end

        it { is_expected.to render_template(:new) }
      end

      context 'when there is no suggested path based from the group name' do
        let(:group_params) { { name: '⛄⛄⛄', path: '' } }

        it 'creates a group, and redirects' do
          expect { subject }.to change { Group.count }.by(1)
          expect(subject).to have_gitlab_http_status(:redirect)
        end
      end

      context 'when group can be created' do
        it 'creates a group' do
          expect { post_import }.to change { Group.count }.by(1)
        end

        it 'passes create_event: true to the Groups::CreateService' do
          expect(Groups::CreateService).to receive(:new).with(user, ActionController::Parameters.new(group_params.merge(create_event: true)).permit!).and_call_original

          post_import
        end

        it 'tracks an event for the combined_registration experiment' do
          expect(experiment(:combined_registration)).to track(:create_group, namespace: an_instance_of(Group))
                                                    .on_next_instance

          post_import
        end

        it 'redirects to the import url with a namespace_id parameter' do
          allow_next_instance_of(::Groups::CreateService) do |service|
            allow(service).to receive(:execute).and_return(group)
          end

          expect(post_import).to redirect_to(new_import_github_url(namespace_id: group.id))
        end
      end
    end
  end

  describe 'PUT #exit' do
    subject(:put_exit) { put :exit }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
        allow(::Gitlab).to receive(:dev_env_or_com?).and_return(true)
      end

      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(root_url) }

      context 'when requires_credit_card_verification is true' do
        let_it_be(:user) { create(:user, requires_credit_card_verification: true) }

        it 'sets requires_credit_card_verification to false' do
          expect { put_exit }.to change { user.reload.requires_credit_card_verification }.to(false)
        end
      end

      context 'when the `exit_registration_verification` feature flag is disabled' do
        before do
          stub_feature_flags(exit_registration_verification: false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end
end
