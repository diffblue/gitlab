# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::ProjectsController do
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project) }

  describe 'GET #new' do
    subject { get :new }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      let(:dev_env_or_com) { true }

      before do
        sign_in(user)
        allow(::Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)
      end

      context 'when on .com' do
        it { is_expected.to have_gitlab_http_status(:not_found) }

        context 'with a namespace in the URL' do
          subject { get :new, params: { namespace_id: namespace.id } }

          it { is_expected.to have_gitlab_http_status(:not_found) }

          context 'with sufficient access' do
            before do
              namespace.add_owner(user)
            end

            it { is_expected.to have_gitlab_http_status(:ok) }
            it { is_expected.to render_template(:new) }
          end
        end
      end

      context 'when not on .com' do
        let(:dev_env_or_com) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    subject { post :create, params: { project: params }.merge(trial_onboarding_flow_params) }

    let_it_be(:trial_onboarding_flow_params) { {} }

    let(:params) { { namespace_id: namespace.id, name: 'New project', path: 'project-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }
    let(:dev_env_or_com) { true }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user', :sidekiq_inline do
      let_it_be(:first_project) { create(:project) }
      let_it_be(:onboarding_context) do
        { learn_gitlab_project_id: project.id, namespace_id: project.namespace_id, project_id: first_project.id }
      end

      before do
        namespace.add_owner(user)
        sign_in(user)
        allow(::Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)
      end

      it 'creates a new project, a "Learn GitLab" project, sets a cookie and redirects to the experience level page' do
        expect { subject }.to change { namespace.projects.pluck(:name) }.from([]).to(['New project', s_('Learn GitLab')])
        expect(subject).to have_gitlab_http_status(:redirect)
        expect(subject).to redirect_to(users_sign_up_experience_level_path(namespace_path: namespace.to_param))
        expect(namespace.projects.find_by_name(s_('Learn GitLab'))).to be_import_finished
      end

      it 'tracks an event for the jobs_to_be_done experiment', :experiment do
        stub_experiments(jobs_to_be_done: :candidate)

        expect(experiment(:jobs_to_be_done)).to track(:create_project, project: an_instance_of(Project))
          .on_next_instance
          .for(:candidate)
          .with_context(user: user)

        subject
      end

      it 'tracks an event for the force_company_trial experiment', :experiment do
        expect(experiment(:force_company_trial)).to track(:create_project, namespace: namespace, project: an_instance_of(Project), user: user)
          .with_context(user: user)
          .on_next_instance

        subject
      end

      it 'tracks learn gitlab experiments' do
        allow_next_instance_of(::Projects::CreateService) do |service|
          allow(service).to receive(:execute).and_return(first_project)
        end
        allow_next_instance_of(::Projects::GitlabProjectsImportService) do |service|
          allow(service).to receive(:execute).and_return(project)
        end
        expect(controller).to receive(:record_experiment_user).with(:learn_gitlab_a, onboarding_context)
        expect(controller).to receive(:record_experiment_user).with(:learn_gitlab_b, onboarding_context)

        subject
      end

      context 'learn gitlab project' do
        using RSpec::Parameterized::TableSyntax

        where(:trial, :experiment_enabled, :project_name, :template) do
          false | false | 'Learn GitLab' | described_class::LEARN_GITLAB_TEMPLATE
          false | true  | 'Learn GitLab' | described_class::LEARN_GITLAB_ULTIMATE_TEMPLATE
          true  | false | 'Learn GitLab - Ultimate trial' | described_class::LEARN_GITLAB_ULTIMATE_TEMPLATE
          true  | true | 'Learn GitLab - Ultimate trial' | described_class::LEARN_GITLAB_ULTIMATE_TEMPLATE
        end

        with_them do
          let(:path) { Rails.root.join('vendor', 'project_templates', template) }
          let(:expected_arguments) { { namespace_id: namespace.id, file: handle, name: project_name } }
          let(:handle) { double }
          let(:trial_onboarding_flow_params) { { trial_onboarding_flow: trial } }

          before do
            stub_experiment_for_subject(learn_gitlab_a: experiment_enabled)
            allow(File).to receive(:open).and_call_original
            expect(File).to receive(:open).with(path).and_yield(handle)
          end

          specify do
            expect_next(::Projects::GitlabProjectsImportService, user, expected_arguments)
              .to receive(:execute).and_return(project)

            subject
          end
        end
      end

      context 'when the trial onboarding is active' do
        let_it_be(:trial_onboarding_flow_params) { { trial_onboarding_flow: true } }

        it 'creates a new project, a "Learn GitLab - Ultimate trial" project, does not set a cookie' do
          expect { subject }.to change { namespace.projects.pluck(:name) }.from([]).to(['New project', s_('Learn GitLab - Ultimate trial')])
          expect(subject).to have_gitlab_http_status(:redirect)
          expect(namespace.projects.find_by_name(s_('Learn GitLab - Ultimate trial'))).to be_import_finished
        end

        it 'records context and redirects to the trial getting started page' do
          expect_next_instance_of(::Projects::CreateService) do |service|
            expect(service).to receive(:execute).and_return(first_project)
          end
          expect_next_instance_of(::Projects::GitlabProjectsImportService) do |service|
            expect(service).to receive(:execute).and_return(project)
          end
          expect(subject).to redirect_to(trial_getting_started_users_sign_up_welcome_path(learn_gitlab_project_id: project.id))
        end
      end

      context 'when the project cannot be saved' do
        let(:params) { { name: '', path: '' } }

        it 'does not create a project' do
          expect { subject }.not_to change { Project.count }
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
        it { is_expected.to render_template(:new) }
      end

      context 'with signup onboarding not enabled' do
        let(:dev_env_or_com) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end
end
