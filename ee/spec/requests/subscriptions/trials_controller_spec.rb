# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::TrialsController, :saas, feature_category: :purchase do
  let_it_be(:user, reload: true) { create(:user) }
  let(:glm_params) { { glm_source: '_glm_source_', glm_content: '_glm_content_' } }

  describe 'GET new' do
    let(:base_params) { glm_params }

    subject(:get_new) do
      get new_trial_path, params: base_params
      response
    end

    context 'when not authenticated' do
      it { is_expected.to redirect_to_trial_registration }
    end

    context 'when authenticated' do
      before do
        login_as(user)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      context 'when not on SaaS' do
        before do
          allow(::Gitlab).to receive(:com?).and_return(false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'with an unconfirmed email address present' do
        let(:user) { create(:user, confirmed_at: nil, unconfirmed_email: 'unconfirmed@gitlab.com') }

        it 'does not show email confirmation warning' do
          get_new

          expect(flash).to be_empty
        end
      end

      context 'when on the trial step' do
        let(:base_params) { { step: 'trial' } }

        it { is_expected.to render_select_namespace }
      end
    end
  end

  describe 'POST create' do
    let(:step) { 'lead' }
    let(:lead_params) do
      {
        company_name: '_company_name_',
        company_size: '1-99',
        first_name: '_first_name_',
        last_name: '_last_name_',
        phone_number: '123',
        country: '_country_',
        state: '_state_',
        website_url: '_website_url_'
      }.with_indifferent_access
    end

    let(:trial_params) do
      {
        namespace_id: non_existing_record_id.to_s,
        trial_entity: '_trial_entity_'
      }.with_indifferent_access
    end

    let(:base_params) { lead_params.merge(trial_params).merge(glm_params).merge(step: step) }

    subject(:post_create) do
      post trials_path, params: base_params
      response
    end

    context 'when not authenticated' do
      it 'redirects to trial registration' do
        expect(post_create).to redirect_to_trial_registration
      end
    end

    context 'when user is banned' do
      before do
        user.ban!
        login_as(user)
      end

      it 'redirects to sign in with banned message' do
        post_create

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to include('Your account has been blocked')
      end
    end

    context 'when authenticated' do
      before do
        login_as(user)
      end

      context 'when user is then banned' do
        before do
          user.ban!
        end

        it 'redirects to trial registration' do
          post_create

          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to include('Your account has been blocked')
        end
      end

      context 'when successful' do
        let(:namespace) { build_stubbed(:namespace) }

        it 'redirects to group path' do
          expect_create_success(namespace)

          expect(post_create).to redirect_to(group_path(namespace, { trial: true }))
        end

        context 'with stored location concerns on redirection' do
          before do
            user.update!(setup_for_company: true)
          end

          context 'when the user is setup for company' do
            context 'when there is a stored location for the user' do
              before do
                allow_next_instance_of(described_class) do |controller|
                  allow(controller).to receive(:stored_location_for).with(:user).and_return(root_path)
                end
              end

              it 'redirects to the stored location' do
                expect_create_success(namespace)

                expect(post_create).to redirect_to(root_path)
              end
            end

            context 'without a stored location set for the user' do
              it 'redirects to the group path' do
                expect_create_success(namespace)

                expect(post_create).to redirect_to(group_path(namespace, { trial: true }))
              end
            end
          end
        end

        where(
          case_names: ->(glm_content) { "when submitted with glm_content value of #{glm_content}" },
          glm_content: %w[discover-group-security discover-project-security]
        )

        with_them do
          let(:glm_params) { { glm_source: '_glm_source_', glm_content: glm_content } }

          it 'redirects to the group security dashboard' do
            expect_create_success(namespace)

            expect(post_create).to redirect_to(group_security_dashboard_path(namespace, { trial: true }))
          end
        end
      end

      context 'with create service failures' do
        let(:payload) { {} }

        before do
          expect_create_failure(failure_reason, payload)
        end

        context 'when namespace is not found or not allowed to create' do
          let(:failure_reason) { :not_found }

          it { is_expected.to have_gitlab_http_status(:not_found) }
        end

        context 'when lead creation fails' do
          let(:failure_reason) { :lead_failed }

          it 'renders lead form' do
            expect(post_create).to have_gitlab_http_status(:ok)

            expect(response.body).to include(_('We have found the following errors:'))
            expect(response.body).to include(_('Start your Free Ultimate Trial'))
            expect(response.body).to include(s_('Trial|Your GitLab Ultimate trial lasts for 30 days, ' \
                                                'but you can keep your free GitLab account forever. ' \
                                                'We just need some additional information to activate your trial.'))
          end
        end

        context 'when lead creation is successful, but we need to select a namespace next to apply trial' do
          let(:failure_reason) { :no_single_namespace }
          let(:payload) do
            {
              trial_selection_params: {
                step: GitlabSubscriptions::Trials::CreateService::TRIAL,
                glm_content: '_glm_content_',
                glm_source: '_glm_source_'
              }
            }
          end

          it 'redirects to new with trial step' do
            post_create

            expect(response).to redirect_to(new_trial_path(payload[:trial_selection_params]))
          end
        end

        context 'with namespace creation failure' do
          let(:failure_reason) { :namespace_create_failed }
          let(:namespace) { build_stubbed(:namespace) }
          let(:payload) { { namespace_id: namespace.id } }

          it 'renders the select namespace form again with namespace creation errors only' do
            expect(post_create).to render_select_namespace

            expect(response.body).to include('data-namespace-create-errors="_error_"')
            expect(response.body).not_to include(_('We have found the following errors:'))
          end
        end

        context 'with trial failure' do
          let(:failure_reason) { :trial_failed }
          let(:namespace) { build_stubbed(:namespace) }
          let(:payload) { { namespace_id: namespace.id } }

          it 'renders the select namespace form again with trial creation errors only' do
            expect(post_create).to render_select_namespace

            expect(response.body).to include(_('We have found the following errors:'))
          end
        end

        context 'with random failure' do
          let(:failure_reason) { :random_error }
          let(:namespace) { build_stubbed(:namespace) }
          let(:payload) { { namespace_id: namespace.id } }

          it { is_expected.to render_select_namespace }
        end
      end

      context 'when not on SaaS' do
        before do
          allow(::Gitlab).to receive(:com?).and_return(false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end

  def expect_create_success(namespace)
    service_params = {
      step: step,
      lead_params: lead_params.merge(glm_params),
      trial_params: trial_params.merge(glm_params),
      user: user
    }

    expect_next_instance_of(GitlabSubscriptions::Trials::CreateService, service_params) do |instance|
      expect(instance).to receive(:execute).and_return(ServiceResponse.success(payload: { namespace: namespace }))
    end
  end

  def expect_create_failure(reason, payload = {})
    # validate params passed/called here perhaps
    expect_next_instance_of(GitlabSubscriptions::Trials::CreateService) do |instance|
      response = ServiceResponse.error(message: '_error_', reason: reason, payload: payload)
      expect(instance).to receive(:execute).and_return(response)
    end
  end

  RSpec::Matchers.define :render_select_namespace do
    match do |response|
      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include(_('Almost there'))
      expect(response.body).to include(_('Start your free trial'))
    end
  end

  RSpec::Matchers.define :redirect_to_trial_registration do
    match do |response|
      expect(response).to redirect_to(new_trial_registration_path(glm_params))
      expect(flash[:alert]).to include('You need to sign in or sign up before continuing')
    end
  end
end
