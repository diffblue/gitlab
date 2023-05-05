# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::CompanyController, :saas, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  let(:logged_in) { true }

  before do
    sign_in(user) if logged_in
  end

  shared_examples 'user authentication' do
    context 'when not authenticated' do
      let(:logged_in) { false }

      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'when authenticated' do
      it { is_expected.to have_gitlab_http_status(:ok) }
    end
  end

  shared_examples 'a dot-com only feature' do
    context 'when not on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when on gitlab.com' do
      it { is_expected.to have_gitlab_http_status(:ok) }
    end
  end

  describe '#new' do
    subject(:get_new) { get :new }

    it_behaves_like 'user authentication'
    it_behaves_like 'a dot-com only feature'

    context 'on render' do
      it { is_expected.to render_template 'layouts/minimal' }
      it { is_expected.to render_template(:new) }

      it 'tracks render event' do
        get_new

        expect_snowplow_event(
          category: described_class.name,
          action: 'render',
          user: user,
          label: 'free_registration'
        )
      end

      context 'when in trial flow' do
        it 'tracks render event' do
          get :new, params: { trial: true }

          expect_snowplow_event(
            category: described_class.name,
            action: 'render',
            user: user,
            label: 'trial_registration'
          )
        end
      end
    end
  end

  describe '#create' do
    using RSpec::Parameterized::TableSyntax

    let(:glm_params) do
      {
        glm_source: 'some_source',
        glm_content: 'some_content'
      }
    end

    let(:params) do
      {
        company_name: 'GitLab',
        company_size: '1-99',
        phone_number: '+1 23 456-78-90',
        country: 'US',
        state: 'CA',
        website_url: 'gitlab.com'
      }.merge(glm_params)
    end

    subject(:post_create) { post :create, params: params }

    context 'on success' do
      where(:trial_onboarding_flow, :redirect_query) do
        'true'  | { trial_onboarding_flow: true }
        'false' | {}
      end

      with_them do
        it 'creates trial or lead and redirects to the correct path' do
          expect_next_instance_of(
            GitlabSubscriptions::CreateTrialOrLeadService,
            user: user,
            params: ActionController::Parameters.new(params.merge(
                                                       trial_onboarding_flow: trial_onboarding_flow
                                                     )).permit!
          ) do |service|
            expect(service).to receive(:execute).and_return(ServiceResponse.success)
          end

          post :create, params: params.merge(trial_onboarding_flow: trial_onboarding_flow)

          expect(response).to have_gitlab_http_status(:redirect)
          expect(response).to redirect_to(new_users_sign_up_groups_project_path(redirect_query.merge(glm_params)))
        end
      end

      context 'when saving onboarding_step_url' do
        let(:path) { new_users_sign_up_groups_project_path(glm_params) }
        let(:should_check_namespace_plan) { true }

        before do
          allow_next_instance_of(GitlabSubscriptions::CreateTrialOrLeadService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.success)
          end
          stub_ee_application_setting(should_check_namespace_plan: should_check_namespace_plan)
        end

        context 'when current user onboarding is disabled' do
          it 'does not store onboarding url' do
            post_create

            expect(user.user_detail.onboarding_step_url).to be_nil
          end
        end

        context 'when ensure_onboarding is disabled' do
          let_it_be(:user) { create(:user, onboarding_in_progress: true) }

          before do
            stub_feature_flags(ensure_onboarding: false)
          end

          it 'does not store onboarding url' do
            post_create

            expect(user.user_detail.onboarding_step_url).to be_nil
          end
        end

        context 'when onboarding and on SaaS' do
          let_it_be(:user) { create(:user, onboarding_in_progress: true) }

          it 'stores onboarding url' do
            post_create

            expect(user.user_detail.onboarding_step_url).to eq(path)
          end
        end

        context 'when not on SaaS' do
          let(:should_check_namespace_plan) { false }

          it 'does not store onboarding url' do
            post_create

            expect(user.user_detail.onboarding_step_url).to be_nil
          end
        end
      end

      context 'with snowplow tracking' do
        before do
          allow_next_instance_of(GitlabSubscriptions::CreateTrialOrLeadService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.success)
          end
        end

        it 'tracks successful submission event' do
          post_create

          expect_snowplow_event(
            category: described_class.name,
            action: 'successfully_submitted_form',
            user: user,
            label: 'free_registration'
          )
        end

        context 'when in trial flow' do
          let(:params) { { trial: 'true' } }

          it 'tracks successful submission event' do
            post_create

            expect_snowplow_event(
              category: described_class.name,
              action: 'successfully_submitted_form',
              user: user,
              label: 'trial_registration'
            )
          end

          it 'does not track submission event with automatic_trial_registration experiment context' do
            stub_experiments(automatic_trial_registration: true)

            expect(controller).not_to receive(:experiment).with(:automatic_trial_registration, actor: user)

            post_create
          end
        end

        it 'tracks successful submission event with automatic_trial_registration experiment context', :experiment do
          expect(experiment(:automatic_trial_registration)).to track(:successfully_submitted_form,
            label: 'free_registration')
            .on_next_instance
            .with_context(actor: user)

          post_create
        end
      end
    end

    context 'on failure' do
      before do
        allow_next_instance_of(GitlabSubscriptions::CreateTrialOrLeadService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'failed'))
        end
      end

      where(trial_onboarding_flow: %w[true false])

      with_them do
        it 'renders company page :new' do
          post :create, params: params.merge(trial_onboarding_flow: trial_onboarding_flow)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:new)
          expect(flash[:alert]).to eq('failed')
        end
      end

      context 'with snowplow tracking' do
        it 'does not track successful submission event' do
          post_create

          expect_no_snowplow_event(
            category: described_class.name,
            action: 'successfully_submitted_form',
            user: user,
            label: 'free_registration'
          )
        end

        context 'when in trial flow' do
          let(:params) { { trial: 'true' } }

          it 'tracks successful submission event' do
            post_create

            expect_no_snowplow_event(
              category: described_class.name,
              action: 'successfully_submitted_form',
              user: user,
              label: 'trial_registration'
            )
          end
        end
      end
    end
  end
end
