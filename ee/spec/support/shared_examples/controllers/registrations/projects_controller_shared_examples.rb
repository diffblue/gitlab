# frozen_string_literal: true

RSpec.shared_examples "Registrations::ProjectsController POST #create" do
  include AfterNextHelpers

  subject { post :create, params: { project: params }.merge(trial_onboarding_flow_params).merge(extra_params) }

  let_it_be(:trial_onboarding_flow_params) { {} }
  let_it_be(:first_project) { create(:project) }

  let(:params) { { namespace_id: namespace.id, name: 'New project', path: 'project-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }
  let(:com) { true }
  let(:extra_params) { {} }
  let(:success_path) { nil }
  let(:stored_location_for) { nil }

  context 'with an unauthenticated user' do
    it { is_expected.to have_gitlab_http_status(:redirect) }
    it { is_expected.to redirect_to(new_user_session_path) }
  end

  context 'with an authenticated user', :sidekiq_inline do
    before do
      namespace.add_owner(user)
      sign_in(user)
      allow(::Gitlab).to receive(:com?).and_return(com)
      allow(controller).to receive(:experiment).and_call_original
    end

    it 'creates a new project, a "Learn GitLab" project, sets a cookie and redirects to the success_path' do
      allow_next_instance_of(::Projects::CreateService) do |service|
        allow(service).to receive(:execute).and_return(first_project)
      end
      allow_next_instance_of(::Projects::GitlabProjectsImportService) do |service|
        allow(service).to receive(:execute).and_return(project)
      end

      expect(subject).to have_gitlab_http_status(:redirect)
      expect(subject).to redirect_to(success_path || continuous_onboarding_getting_started_users_sign_up_welcome_path(project_id: first_project.id))
      expect(controller.stored_location_for(:user)).to eq(stored_location_for)
    end

    context 'when the `registration_verification` experiment is enabled' do
      before do
        stub_experiments(registration_verification: :candidate)

        allow_next_instance_of(::Projects::CreateService) do |service|
          allow(service).to receive(:execute).and_return(first_project)
        end
      end

      it 'is expected to redirect to the verification page' do
        params = { project_id: first_project.id }
        params[:combined] = true if combined_registration?
        expect(subject).to redirect_to(new_users_sign_up_verification_path(params))
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
        let(:expected_arguments) { { namespace_id: namespace.id, file: handle, name: project_name } }
        let(:handle) { double }
        let(:trial_onboarding_flow_params) { { trial_onboarding_flow: trial } }

        before do
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
        expect { subject }.to change { namespace.projects.pluck(:name).sort }.from([]).to(['New project', s_('Learn GitLab - Ultimate trial')].sort)
        expect(subject).to have_gitlab_http_status(:redirect)
        expect(namespace.projects.find_by_name(s_('Learn GitLab - Ultimate trial'))).to be_import_finished
      end

      it 'records context and redirects to the success page' do
        expect_next_instance_of(::Projects::CreateService) do |service|
          expect(service).to receive(:execute).and_return(first_project)
        end
        expect_next_instance_of(::Projects::GitlabProjectsImportService) do |service|
          expect(service).to receive(:execute).and_return(project)
        end
        expect(subject).to redirect_to(trial_getting_started_users_sign_up_welcome_path(learn_gitlab_project_id: project.id))
      end

      context 'when the `registration_verification` experiment is enabled' do
        before do
          stub_experiments(registration_verification: :candidate)

          allow_next_instance_of(::Projects::GitlabProjectsImportService) do |service|
            allow(service).to receive(:execute).and_return(project)
          end
        end

        it 'is expected to redirect to the verification page' do
          params = { learn_gitlab_project_id: project.id }
          params[:combined] = true if combined_registration?
          expect(subject).to redirect_to(new_users_sign_up_verification_path(params))
        end
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
      let(:com) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end
