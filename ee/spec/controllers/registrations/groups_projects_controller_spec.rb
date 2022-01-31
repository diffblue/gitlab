# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::GroupsProjectsController, :experiment do
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

        context 'it redirects' do
          let_it_be(:project) { create(:project) }

          before do
            allow_next_instance_of(::Projects::CreateService) do |service|
              allow(service).to receive(:execute).and_return(project)
            end
          end

          it { is_expected.to redirect_to(continuous_onboarding_getting_started_users_sign_up_welcome_path(project_id: project.id)) }
        end
      end
    end

    shared_context 'groups_projects projects concern' do
      let_it_be(:project) { create(:project) }
      let_it_be(:namespace) { create(:group) }

      let(:group_params) { { name: 'Group name', path: 'group-path', visibility_level: "#{Gitlab::VisibilityLevel::PRIVATE}", setup_for_company: setup_for_company } }
      let(:extra_params) { { group: group_params } }
      let(:params) { { name: 'New project', path: 'project-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }
      let(:create_service) { double(:create_service) }

      before do
        allow(controller).to receive(:record_experiment_user).and_call_original
        allow(controller).to receive(:record_experiment_conversion_event).and_call_original

        allow(Groups::CreateService).to receive(:new).and_call_original
        allow(Groups::CreateService).to receive(:new).with(user, ActionController::Parameters.new(group_params.merge(create_event: true)).permit!).and_return(create_service)
        allow(create_service).to receive(:execute).and_return(namespace)
      end
    end

    it_behaves_like "Registrations::ProjectsController POST #create" do
      include_context 'groups_projects projects concern'
    end

    context 'when the user is setup_for_company: true it redirects to the new_trial_path' do
      let(:setup_for_company) { true }

      it_behaves_like "Registrations::ProjectsController POST #create" do
        let_it_be(:first_project) { create(:project) }

        let(:user) { create(:user, setup_for_company: setup_for_company) }
        let(:success_path) { new_trial_path }
        let(:stored_location_for) { continuous_onboarding_getting_started_users_sign_up_welcome_path(project_id: first_project.id) }

        include_context 'groups_projects projects concern'
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
end
