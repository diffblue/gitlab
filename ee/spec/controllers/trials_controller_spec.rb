# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialsController do
  let_it_be(:user) { create(:user, email_opted_in: true, last_name: 'Doe') }
  let_it_be(:remove_known_trial_form_fields_context) do
    {
      first_name_present: user.first_name.present?,
      last_name_present: user.last_name.present?,
      company_name_present: user.organization.present?
    }
  end

  let(:dev_env_or_com) { true }
  let(:logged_in) { true }

  before do
    allow(::Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)
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

    context 'when not on gitlab.com and not in development environment' do
      let(:dev_env_or_com) { false }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when on gitlab.com or in dev environment' do
      it { is_expected.to have_gitlab_http_status(success_status) }
    end
  end

  describe '#new' do
    subject do
      get :new
      response
    end

    it 'calls record_experiment_user for the experiments' do
      expect(controller).to receive(:record_experiment_user).with(:remove_known_trial_form_fields, remove_known_trial_form_fields_context)

      subject
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'
  end

  describe '#create_lead' do
    let(:post_params) { {} }
    let(:create_lead_result) { nil }

    before do
      allow_next_instance_of(GitlabSubscriptions::CreateLeadService) do |lead_service|
        expect(lead_service).to receive(:execute).and_return({ success: create_lead_result })
      end
    end

    subject do
      post :create_lead, params: post_params
      response
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'

    context 'on success' do
      let(:create_lead_result) { true }

      it { is_expected.to redirect_to(select_trials_url) }

      context 'coming from about.gitlab.com' do
        let(:post_params) { { glm_source: 'about.gitlab.com' } }

        it 'records trial_onboarding_issues experiment users but does not redirect to onboarding' do
          expect(controller).to receive(:record_experiment_user).with(:trial_onboarding_issues)
          is_expected.to redirect_to(select_trials_url(glm_source: 'about.gitlab.com'))
        end

        context 'when experiment trial_onboarding_issues is enabled' do
          before do
            stub_experiment_for_subject(trial_onboarding_issues: true)
          end

          it 'records trial_onboarding_issues experiment users and redirects to onboarding' do
            expect(controller).to receive(:record_experiment_user).with(:trial_onboarding_issues)

            is_expected.to redirect_to(new_users_sign_up_group_path(glm_source: 'about.gitlab.com', trial_onboarding_flow: true))
          end
        end
      end
    end

    context 'on failure' do
      let(:create_lead_result) { false }

      it { is_expected.to render_template(:new) }
    end

    context 'request params to Lead Service' do
      let(:post_params) do
        {
          company_name: 'Gitlab',
          company_size: '1-99',
          first_name: user.first_name,
          last_name: user.last_name,
          phone_number: '1111111111',
          number_of_users: "20",
          country: 'IN'
        }
      end

      let(:extra_params) do
        {
          work_email: user.email,
          uid: user.id,
          skip_email_confirmation: true,
          gitlab_com_trial: true,
          provider: 'gitlab',
          newsletter_segment: user.email_opted_in
        }
      end

      let(:expected_params) do
        ActionController::Parameters.new(post_params).merge(extra_params).permit!
      end

      it 'sends appropriate request params' do
        expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |lead_service|
          expect(lead_service).to receive(:execute).with({ trial_user: expected_params }).and_return({ success: true })
        end

        subject
      end
    end
  end

  describe '#select' do
    subject do
      get :select
      response
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'
  end

  describe '#apply' do
    let_it_be(:namespace) { create(:group, path: 'namespace-test') }

    let(:apply_trial_result) { nil }
    let(:post_params) { { namespace_id: namespace.id } }

    before do
      namespace.add_owner(user)

      allow_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
        allow(service).to receive(:execute).and_return({ success: apply_trial_result })
      end
    end

    subject do
      post :apply, params: post_params
      response
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'

    context 'on success' do
      let(:apply_trial_result) { true }

      it { is_expected.to redirect_to("/#{namespace.path}?trial=true") }
      it 'calls the record conversion method for the experiments' do
        expect(controller).to receive(:record_experiment_user).with(:remove_known_trial_form_fields, namespace_id: namespace.id)
        expect(controller).to receive(:record_experiment_user).with(:trial_onboarding_issues, namespace_id: namespace.id)
        expect(controller).to receive(:record_experiment_conversion_event).with(:remove_known_trial_form_fields)
        expect(controller).to receive(:record_experiment_conversion_event).with(:trial_onboarding_issues)

        subject
      end

      context 'in discover group security flow' do
        let(:post_params) { { namespace_id: namespace.id, glm_content: 'discover-group-security' } }

        context 'with redirect_trial_user_to_feature experiment variant' do
          before do
            stub_experiments(redirect_trial_user_to_feature: :candidate)
          end

          it { is_expected.to redirect_to(group_security_dashboard_url(namespace, { trial: true })) }
          it 'records the subject' do
            expect(Experiment).to receive(:add_subject).with('redirect_trial_user_to_feature', variant: :experimental, subject: namespace)

            subject
          end
        end

        context 'with redirect_trial_user_to_feature experiment control' do
          before do
            stub_experiments(redirect_trial_user_to_feature: :control)
          end

          it { is_expected.to redirect_to(group_url(namespace, { trial: true })) }
          it 'records the subject' do
            expect(Experiment).to receive(:add_subject).with('redirect_trial_user_to_feature', variant: :control, subject: namespace)

            subject
          end
        end
      end

      context 'with a new Group' do
        let(:post_params) { { new_group_name: 'GitLab' } }

        it 'creates the Group' do
          expect { subject }.to change { Group.count }.by(1)
        end
      end
    end

    context 'on failure' do
      let(:apply_trial_result) { false }

      it { is_expected.to render_template(:select) }
      it 'does not call the record conversion method for the experiments' do
        expect(controller).not_to receive(:record_experiment_conversion_event).with(:remove_known_trial_form_fields)

        subject
      end

      context 'with a new Group' do
        let(:post_params) { { new_group_name: 'admin' } }

        it { is_expected.to render_template(:select) }

        it 'does not create the Group' do
          expect { subject }.not_to change { Group.count }
        end
      end
    end

    it "calls the ApplyTrialService with correct parameters" do
      gl_com_params = { gitlab_com_trial: true, sync_to_gl: true }
      post_params = {
        namespace_id: namespace.id.to_s,
        trial_entity: 'company',
        glm_source: 'source',
        glm_content: 'content'
      }
      apply_trial_params = {
        uid: user.id,
        trial_user:  ActionController::Parameters.new(post_params).permit(:namespace_id, :trial_entity, :glm_source, :glm_content).merge(gl_com_params)
      }

      expect_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
        expect(service).to receive(:execute).with(apply_trial_params).and_return({ success: true })
      end

      post :apply, params: post_params
    end
  end

  describe '#extend_reactivate' do
    let!(:namespace) { create(:group_with_plan, trial_ends_on: Date.tomorrow, path: 'namespace-test') }

    let(:namespace_id) { namespace.id }
    let(:trial_extension_type) { GitlabSubscription.trial_extension_types[:extended].to_s }
    let(:put_params) { { namespace_id: namespace_id, trial_extension_type: trial_extension_type } }
    let(:extend_reactivate_trial_result) { true }
    let(:is_owner?) { true }

    before do
      if is_owner?
        namespace.add_owner(user)
      else
        namespace.add_developer(user)
      end

      allow_next_instance_of(GitlabSubscriptions::ExtendReactivateTrialService) do |service|
        allow(service).to receive(:execute).and_return(extend_reactivate_trial_result ? ServiceResponse.success : ServiceResponse.error(message: 'failed'))
      end
    end

    subject do
      put :extend_reactivate, params: put_params
      response
    end

    it_behaves_like 'an authenticated endpoint'
    it_behaves_like 'a dot-com only feature'

    context 'on success' do
      it { is_expected.to have_gitlab_http_status(:ok) }
    end

    context 'on failure' do
      context 'when user is not namespace owner' do
        let(:is_owner?) { false }

        it 'returns 403' do
          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when cannot find the namespace' do
        let(:namespace_id) { 'invalid-namespace-id' }

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
          namespace.gitlab_subscription.update_column(:trial_extension_type, GitlabSubscription.trial_extension_types[:extended])

          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when trial extension type is REACTIVATE' do
        let(:trial_extension_type) { GitlabSubscription.trial_extension_types[:reactivated].to_s }

        it 'returns 403 if the namespace cannot reactivate' do
          namespace.gitlab_subscription.update_column(:trial_extension_type, GitlabSubscription.trial_extension_types[:extended])

          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when ExtendReactivateTrialService fails' do
        let(:extend_reactivate_trial_result) { false }

        it 'returns 403' do
          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end
    end

    it "calls the ExtendReactivateTrialService with correct parameters" do
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
        trial_user:  ActionController::Parameters.new(put_params).permit(:namespace_id, :trial_extension_type, :trial_entity, :glm_source, :glm_content).merge(gl_com_params)
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
      match do |response|
        expect(controller).to set_flash.now[:warning].to include("Please check your email (#{email}) to verify that you own this address and unlock the power of CI/CD.")
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
end
