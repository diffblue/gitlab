# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::GroupsProjectsController, :experiment, feature_category: :onboarding do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  shared_examples 'finishing onboarding' do
    let_it_be(:url) { '_url_' }
    let_it_be(:onboarding_in_progress) { true }
    let(:should_check_namespace_plan) { true }

    let_it_be(:user) do
      create(:user, onboarding_in_progress: onboarding_in_progress).tap do |record|
        create(:user_detail, user: record, onboarding_step_url: url)
      end
    end

    before do
      stub_ee_application_setting(should_check_namespace_plan: should_check_namespace_plan)
    end

    context 'when current user onboarding is disabled' do
      let_it_be(:onboarding_in_progress) { false }

      it 'does not finish onboarding' do
        subject

        expect(user.user_detail.onboarding_step_url).to eq url
      end
    end

    context 'when not on SaaS' do
      let(:should_check_namespace_plan) { false }

      it 'does not finish onboarding' do
        subject

        expect(user.user_detail.onboarding_step_url).to eq url
      end
    end

    context 'when ensure_onboarding is disabled' do
      before do
        stub_feature_flags(ensure_onboarding: false)
      end

      it 'does not finish onboarding' do
        subject

        expect(user.user_detail.onboarding_step_url).to eq url
      end
    end

    context 'when onboarding is enabled' do
      it 'finishes onboarding' do
        subject
        user.reload

        expect(user.user_detail.onboarding_step_url).to be_nil
        expect(user.onboarding_in_progress).to be_falsey
      end
    end
  end

  describe 'GET #new' do
    subject(:get_new) { get :new }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
      end

      context 'when on .com', :saas do
        it { is_expected.to have_gitlab_http_status(:ok) }
        it { is_expected.to render_template(:new) }

        it 'assigns the group variable to a new Group with the default group visibility', :aggregate_failures do
          get_new

          expect(assigns(:group)).to be_a_new(Group)
          expect(assigns(:group).visibility_level).to eq(Gitlab::CurrentSettings.default_group_visibility)
        end

        it 'builds a project object' do
          get_new

          expect(assigns(:project)).to be_a_new(Project)
        end

        it 'tracks the new group view event' do
          get_new

          expect_snowplow_event(
            category: described_class.name,
            action: 'view_new_group_action',
            label: 'free_registration',
            user: user
          )
        end

        context 'when on trial' do
          it 'tracks the new group view event' do
            get :new, params: { trial_onboarding_flow: true }

            expect_snowplow_event(
              category: described_class.name,
              action: 'view_new_group_action',
              label: 'trial_registration',
              user: user
            )
          end
        end

        context 'when user does not have the ability to create a group' do
          let(:user) { create(:user, can_create_group: false) }

          it { is_expected.to have_gitlab_http_status(:not_found) }
        end
      end

      context 'when not on .com' do
        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      it_behaves_like 'hides email confirmation warning'
    end
  end

  describe 'POST #create' do
    subject(:post_create) { post :create, params: params }

    let(:com) { true }
    let(:params) { { group: group_params, project: project_params }.merge(extra_params) }
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

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
        allow(::Gitlab).to receive(:com?).and_return(com)
      end

      it_behaves_like 'hides email confirmation warning'
      it_behaves_like 'finishing onboarding'

      it 'creates a group and project' do
        expect { post_create }.to change { Group.count }.by(1).and change { Project.count }.by(1)
      end

      it 'tracks submission event' do
        post_create

        expect_snowplow_event(
          category: described_class.name,
          action: 'successfully_submitted_form',
          label: 'free_registration',
          user: user
        )
      end

      context 'when on trial' do
        let(:extra_params) { { trial_onboarding_flow: true } }

        it 'tracks submission event' do
          post_create

          expect_snowplow_event(
            category: described_class.name,
            action: 'successfully_submitted_form',
            label: 'trial_registration',
            user: user
          )
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

        it 'the project is not disregarded completely' do
          post_create

          expect(assigns(:project).name).to eq('New project')
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
        it { is_expected.to render_template(:new) }

        it 'does not tracks submission event' do
          post_create

          expect_no_snowplow_event(
            category: described_class.name,
            action: 'successfully_submitted_form',
            label: 'free_registration',
            user: user
          )
        end
      end

      context 'with signup onboarding not enabled' do
        let(:com) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context "when group can be created but the project can't" do
        let(:project_params) { { name: '', path: '', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

        it 'does not create a project', :aggregate_failures do
          expect { post_create }.to change { Group.count }
          expect { post_create }.not_to change { Project.count }
          expect(assigns(:project).errors).not_to be_blank
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
      end

      context 'when redirecting' do
        let_it_be(:project) { create(:project) }

        let(:success_path) { onboarding_project_learn_gitlab_path(project) }

        before do
          allow_next_instance_of(::Projects::CreateService) do |service|
            allow(service).to receive(:execute).and_return(project)
          end
        end

        it { is_expected.to redirect_to(success_path) }

        context 'when trial_onboarding_flow' do
          let(:extra_params) { { trial_onboarding_flow: true } }
          let(:success_path) { onboarding_project_learn_gitlab_path(project, trial_onboarding_flow: true) }

          it { is_expected.to redirect_to(success_path) }
        end

        context 'when the `registration_verification` experiment is enabled' do
          before do
            stub_experiments(registration_verification: :candidate)
          end

          it 'is expected to store the success path and redirect to the verification page' do
            expect(subject).to redirect_to(new_users_sign_up_verification_path(project_id: project.id))
            expect(controller.stored_location_for(:user)).to eq(success_path)
          end
        end
      end
    end
  end

  describe 'POST #import', :saas do
    subject(:post_import) { post :import, params: params }

    let(:params) { { group: group_params, import_url: new_import_github_path } }
    let(:group_params) do
      {
        name: 'Group name',
        path: 'group-path',
        visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s
      }
    end

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
      end

      it_behaves_like 'hides email confirmation warning'
      it_behaves_like 'finishing onboarding'

      context "when a group can't be created" do
        before do
          allow_next_instance_of(::Groups::CreateService) do |service|
            allow(service).to receive(:execute).and_return(Group.new)
          end
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
