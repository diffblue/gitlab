# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialsController, :saas, feature_category: :purchase do
  let_it_be(:user) { create(:user, email_opted_in: true, last_name: 'Doe') }

  let(:logged_in) { true }

  before do
    sign_in(user) if logged_in
  end

  shared_examples 'an authenticated endpoint' do
    let(:success_status) { :ok }

    context 'when not authenticated' do
      let(:logged_in) { false }

      it { is_expected.to redirect_to(new_trial_registration_url) }
    end

    context 'when authenticated' do
      it { is_expected.to have_gitlab_http_status(success_status) }
    end
  end

  shared_examples 'a dot-com only feature' do
    let(:success_status) { :ok }

    context 'when not on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when on gitlab.com' do
      it { is_expected.to have_gitlab_http_status(success_status) }
    end
  end

  describe '#new' do
    subject(:get_new) do
      get :new
      response
    end

    it 'calls record_experiment_user for the experiments' do
      get_new
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'
  end

  describe '#create_lead' do
    let(:post_params) { {} }
    let(:create_lead_result) { ServiceResponse.success }

    before do
      allow_next_instance_of(GitlabSubscriptions::CreateLeadService) do |lead_service|
        expect(lead_service).to receive(:execute).and_return(create_lead_result) # rubocop:disable RSpec/ExpectInHook
      end
    end

    subject(:post_create_lead) do
      post :create_lead, params: post_params
      response
    end

    context 'when not authenticated' do
      let(:logged_in) { false }

      it { is_expected.to redirect_to(new_trial_registration_url) }
    end

    context 'when not on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'with success' do
      let(:post_params) { { glm_source: '_glm_source_', glm_content: '_glm_content_' } }

      it { is_expected.to redirect_to(select_trials_path(post_params)) }

      context 'when user has 1 trial eligible namespace', :experiment do
        let_it_be(:namespace) { create(:group, path: 'namespace-test') }

        let(:apply_trial_result) do
          instance_double(GitlabSubscriptions::Trials::ApplyTrialService, execute: ServiceResponse.success)
        end

        before do
          namespace.add_owner(user)

          allow(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(apply_trial_result)
        end

        context 'when the ApplyTrialService is successful' do
          it 'applies a trial to the namespace' do
            apply_trial_params = {
              uid: user.id,
              trial_user_information: ActionController::Parameters
                                        .new(post_params).permit(:namespace_id, :glm_source, :glm_content)
                                        .merge(namespace_id: namespace.id,
                                               gitlab_com_trial: true,
                                               sync_to_gl: true)
            }

            expect_next_instance_of(GitlabSubscriptions::Trials::ApplyTrialService, apply_trial_params) do |instance|
              expect(instance).to receive(:execute).and_return(ServiceResponse.success)
            end

            post_create_lead
          end

          it 'tracks for the trial creation' do
            post_create_lead

            expect_snowplow_event(category: described_class.name,
                                  action: 'create_trial',
                                  namespace: namespace,
                                  user: user)
          end

          context 'when the user is `setup_for_company: true`' do
            let(:user) { create(:user, setup_for_company: true) }

            context 'when there is a stored_location_for(:user) set' do
              let(:stored_location_for) do
                onboarding_project_learn_gitlab_path(build(:project))
              end

              before do
                controller.store_location_for(:user, stored_location_for)
              end

              it { is_expected.to redirect_to(stored_location_for) }
            end

            it { is_expected.to redirect_to(group_url(namespace, { trial: true })) }
          end

          it { is_expected.to redirect_to(group_url(namespace, { trial: true })) }
        end

        context 'when the ApplyTrialService is unsuccessful' do
          let(:apply_trial_result) do
            instance_double(GitlabSubscriptions::Trials::ApplyTrialService,
                            execute: ServiceResponse.error(message: '_fail_'))
          end

          it { is_expected.to render_template(:select) }
        end
      end
    end

    context 'with failure' do
      render_views

      let(:create_lead_result) { ServiceResponse.error(message: '_fail_') }

      it { is_expected.to render_template(:new) }
    end

    context 'with request params to Lead Service' do
      let(:post_params) do
        {
          company_name: 'Gitlab',
          company_size: '1-99',
          first_name: user.first_name,
          last_name: user.last_name,
          phone_number: '1111111111',
          country: 'US',
          state: 'CA',
          glm_content: 'free-billing',
          glm_source: 'about.gitlab.com'
        }
      end

      let(:extra_params) do
        {
          work_email: user.email,
          uid: user.id,
          setup_for_company: nil,
          skip_email_confirmation: true,
          gitlab_com_trial: true,
          provider: 'gitlab',
          newsletter_segment: user.email_opted_in
        }
      end

      let(:expected_params) do
        {
          company_name: 'Gitlab',
          company_size: '1-99',
          first_name: user.first_name,
          last_name: user.last_name,
          phone_number: '1111111111',
          country: 'US',
          state: 'CA',
          glm_content: 'free-billing',
          glm_source: 'about.gitlab.com',
          work_email: user.email,
          uid: user.id,
          setup_for_company: nil,
          skip_email_confirmation: true,
          gitlab_com_trial: true,
          provider: 'gitlab',
          newsletter_segment: user.email_opted_in
        }
      end

      it 'sends appropriate request params' do
        expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |lead_service|
          expect(lead_service).to receive(:execute)
                                    .with({ trial_user: ActionController::Parameters.new(expected_params).permit! })
                                    .and_return(ServiceResponse.success)
        end

        post_create_lead
      end
    end
  end

  describe '#create_hand_raise_lead' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:namespace_id) { namespace.id.to_s }

    let(:create_hand_raise_lead_result) { ServiceResponse.success }
    let(:hand_raise_lead_extra_params) do
      {
        work_email: user.email,
        uid: user.id,
        provider: 'gitlab',
        setup_for_company: user.setup_for_company,
        glm_source: 'gitlab.com'
      }
    end

    let(:post_params) do
      {
        namespace_id: namespace_id,
        first_name: 'James',
        last_name: 'Bond',
        company_name: 'ACME',
        company_size: '1-99',
        phone_number: '+1-192-10-10',
        country: 'US',
        state: 'CA',
        comment: 'I want to talk to sales.',
        glm_content: 'group-billing'
      }
    end

    subject do
      post :create_hand_raise_lead, params: post_params
      response
    end

    before_all do
      namespace.add_developer(user)
    end

    before do
      allow_next_instance_of(GitlabSubscriptions::CreateHandRaiseLeadService) do |service|
        allow(service).to receive(:execute).and_return(create_hand_raise_lead_result)
      end
    end

    it_behaves_like 'a dot-com only feature'

    context 'when not authenticated' do
      let(:logged_in) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when cannot find the namespace' do
      let(:namespace_id) { non_existing_record_id.to_s }

      it 'returns 404' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    context 'when CreateHandRaiseLeadService fails' do
      let(:create_hand_raise_lead_result) { ServiceResponse.error(message: '_fail_') }

      it 'returns 403' do
        is_expected.to have_gitlab_http_status(:forbidden)
      end
    end

    it 'calls the CreateHandRaiseLeadService with correct parameters' do
      expect_next_instance_of(GitlabSubscriptions::CreateHandRaiseLeadService) do |service|
        expected_params = ActionController::Parameters.new(post_params)
                            .permit!
                            .merge(hand_raise_lead_extra_params)
        expect(service).to receive(:execute).with(expected_params).and_return(ServiceResponse.success)
      end

      post :create_hand_raise_lead, params: post_params
    end
  end

  describe '#select' do
    subject(:get_select) do
      get :select
      response
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'
  end

  describe '#apply' do
    let_it_be(:namespace) { create(:group, path: 'namespace-test') }

    let(:post_params) { { namespace_id: namespace.id } }
    let(:apply_trial_result) do
      instance_double(GitlabSubscriptions::Trials::ApplyTrialService, execute: ServiceResponse.error(message: '_fail_'))
    end

    before do
      namespace.add_owner(user)

      allow(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(apply_trial_result)
      allow(controller).to receive(:experiment).and_call_original
    end

    subject(:post_apply) do
      post :apply, params: post_params
      response
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'

    context 'with success' do
      let(:apply_trial_result) do
        instance_double(GitlabSubscriptions::Trials::ApplyTrialService, execute: ServiceResponse.success)
      end

      it { is_expected.to redirect_to("/#{namespace.path}?trial=true") }

      it 'tracks the trial creation event' do
        subject

        expect_snowplow_event(category: described_class.name,
                              action: 'create_trial',
                              namespace: namespace,
                              user: user)
      end

      context 'with redirect trial user to feature' do
        using RSpec::Parameterized::TableSyntax

        where(:glm_content, :redirect) do
          'discover-group-security' | :group_security_dashboard_url
          'discover-project-security' | :group_security_dashboard_url
        end

        with_them do
          let(:post_params) { { namespace_id: namespace.id, glm_content: glm_content } }
          let(:redirect_url) { group_security_dashboard_url(namespace, { trial: true }) }

          it { is_expected.to redirect_to(redirect_url) }
        end
      end

      context 'with a new Group' do
        let(:post_params) { { new_group_name: 'GitLab' } }

        it 'creates the Group' do
          expect { post_apply }.to change { Group.count }.by(1)
        end
      end
    end

    context 'with failure' do
      let(:apply_trial_result) do
        instance_double(GitlabSubscriptions::Trials::ApplyTrialService,
                        execute: ServiceResponse.error(message: '_failed_'))
      end

      it { is_expected.to render_template(:select) }

      it 'does not call the record conversion method for the experiments' do
        post_apply
      end

      context 'with a new Group' do
        let(:post_params) { { new_group_name: 'admin' } }

        it { is_expected.to render_template(:select) }

        it 'does not create the Group' do
          expect { post_apply }.not_to change { Group.count }
        end
      end
    end

    it 'calls the ApplyTrialService with correct parameters' do
      gl_com_params = { gitlab_com_trial: true, sync_to_gl: true }
      post_params = {
        namespace_id: namespace.id.to_s,
        trial_entity: 'company',
        glm_source: 'source',
        glm_content: 'content'
      }
      apply_trial_params = {
        uid: user.id,
        trial_user_information: ActionController::Parameters.new(post_params)
                                                            .permit(
                                                              :namespace_id,
                                                              :trial_entity,
                                                              :glm_source,
                                                              :glm_content
                                                            ).merge(gl_com_params)
      }

      expect_next_instance_of(GitlabSubscriptions::Trials::ApplyTrialService, apply_trial_params) do |instance|
        expect(instance).to receive(:execute).and_return(ServiceResponse.success)
      end

      post :apply, params: post_params
    end
  end

  describe '#extend_reactivate' do
    let!(:namespace) { create(:group_with_plan, trial_ends_on: Date.tomorrow, path: 'namespace-test') }

    let(:namespace_id) { namespace.id }
    let(:trial_extension_type) { GitlabSubscription.trial_extension_types[:extended].to_s }
    let(:put_params) { { namespace_id: namespace_id, trial_extension_type: trial_extension_type } }
    let(:extend_reactivate_trial_result) { ServiceResponse.success }
    let(:is_owner?) { true }

    before do
      if is_owner?
        namespace.add_owner(user)
      else
        namespace.add_developer(user)
      end

      allow_next_instance_of(GitlabSubscriptions::ExtendReactivateTrialService) do |service|
        allow(service).to receive(:execute).and_return(extend_reactivate_trial_result)
      end
    end

    subject do
      put :extend_reactivate, params: put_params
      response
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'

    context 'with success' do
      it { is_expected.to have_gitlab_http_status(:ok) }
    end

    context 'with failure' do
      context 'when user is not namespace owner' do
        let(:is_owner?) { false }

        it 'returns 403' do
          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when cannot find the namespace' do
        let(:namespace_id) { non_existing_record_id.to_s }

        it 'returns 404' do
          is_expected.to have_gitlab_http_status(:not_found)
        end
      end

      context 'when trial extension type is neither EXTEND nor REACTIVATE' do
        let(:trial_extension_type) { nil }

        it 'returns 403' do
          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when trial extension type is EXTEND' do
        let(:trial_extension_type) { GitlabSubscription.trial_extension_types[:extended].to_s }

        it 'returns 403 if the namespace cannot extend' do
          namespace.gitlab_subscription
                   .update!(trial_extension_type: GitlabSubscription.trial_extension_types[:extended])

          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when trial extension type is REACTIVATE' do
        let(:trial_extension_type) { GitlabSubscription.trial_extension_types[:reactivated].to_s }

        it 'returns 403 if the namespace cannot reactivate' do
          namespace.gitlab_subscription
                   .update!(trial_extension_type: GitlabSubscription.trial_extension_types[:extended])

          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when ExtendReactivateTrialService fails' do
        let(:extend_reactivate_trial_result) { ServiceResponse.error(message: '_fail_') }

        it 'returns 403' do
          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end
    end

    it 'calls the ExtendReactivateTrialService with correct parameters' do
      gl_com_params = { gitlab_com_trial: true }
      put_params = {
        namespace_id: namespace.id.to_s,
        trial_extension_type: GitlabSubscription.trial_extension_types[:extended].to_s,
        trial_entity: 'company',
        glm_source: 'source',
        glm_content: 'content'
      }
      extend_reactivate_trial_params = {
        uid: user.id,
        trial_user: ActionController::Parameters.new(put_params)
                      .permit(
                        :namespace_id,
                        :trial_extension_type,
                        :trial_entity,
                        :glm_source,
                        :glm_content
                      ).merge(gl_com_params)
      }

      expect_next_instance_of(GitlabSubscriptions::ExtendReactivateTrialService) do |service|
        expect(service).to receive(:execute).with(extend_reactivate_trial_params).and_return(ServiceResponse.success)
      end

      put :extend_reactivate, params: put_params
    end
  end

  describe 'confirm email warning' do
    before do
      get :new
    end

    RSpec::Matchers.define :set_confirm_warning_for do |email|
      match do |_response|
        msg = "Please check your email (#{email}) to verify that you own this address and unlock the power of CI/CD."
        expect(controller).to set_flash.now[:warning].to include(msg)
      end
    end

    context 'with an unconfirmed email address present' do
      let(:user) { create(:user, confirmed_at: nil, unconfirmed_email: 'unconfirmed@gitlab.com') }

      before do
        sign_in(user)
      end

      it { is_expected.not_to set_confirm_warning_for(user.unconfirmed_email) }
    end

    context 'without an unconfirmed email address present' do
      let(:user) { create(:user, confirmed_at: nil) }

      it { is_expected.not_to set_confirm_warning_for(user.email) }
    end
  end

  describe '#skip' do
    subject(:get_skip) { get :skip, params: params }

    let(:params) { {} }

    context 'when the user is `setup_for_company: true`' do
      let(:user) { create(:user, setup_for_company: true) }

      it { is_expected.to redirect_to(dashboard_projects_path) }

      context 'with has a stored_location_for set' do
        before do
          controller.store_location_for(:user, new_trial_path)
        end

        it { is_expected.to redirect_to(new_trial_path) }
      end
    end

    context 'when the user is `setup_for_company: false`' do
      it { is_expected.to redirect_to(dashboard_projects_path) }
    end
  end
end
