# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::GroupsController do
  describe 'GET #new' do
    it_behaves_like "Registrations::GroupsController GET #new"
  end

  describe 'POST #create', :aggregate_failure do
    let_it_be(:user) { create(:user) }
    let_it_be(:glm_params) { {} }
    let_it_be(:trial_form_params) { { trial: 'false' } }
    let_it_be(:trial_onboarding_flow_params) { {} }

    let(:com) { true }
    let(:group_params) { { name: 'Group name', path: 'group-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s, create_event: true, setup_for_company: setup_for_company } }
    let(:setup_for_company) { nil }
    let(:params) do
      { group: group_params }.merge(glm_params).merge(trial_form_params).merge(trial_onboarding_flow_params)
    end

    subject(:post_create) { post :create, params: params }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
        allow(::Gitlab).to receive(:com?).and_return(com)
      end

      context 'when on .com' do
        it_behaves_like 'hides email confirmation warning'

        context 'when group can be created' do
          it 'creates a group' do
            expect { post_create }.to change { Group.count }.by(1)
          end

          it 'passes group_params to Groups::CreateService' do
            expect(Groups::CreateService).to receive(:new).with(user, ActionController::Parameters.new(group_params).permit!).and_call_original

            post_create
          end

          context 'when the user is `setup_for_company: true`' do
            let(:user) { create(:user, setup_for_company: setup_for_company) }
            let(:setup_for_company) { true }

            it 'passes `setup_for_company: true` to the Groups::CreateService' do
              expect(Groups::CreateService).to receive(:new).with(user, ActionController::Parameters.new(group_params).permit!).and_call_original

              post_create
            end
          end

          context 'when in trial onboarding  - apply_trial_for_trial_onboarding_flow' do
            let_it_be(:group) { create(:group) }
            let_it_be(:trial_onboarding_flow_params) { { trial_onboarding_flow: true, glm_source: 'about.gitlab.com', glm_content: 'content' } }
            let_it_be(:apply_trial_params) do
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
              expect_next_instance_of(::Groups::CreateService) do |service|
                expect(service).to receive(:execute).and_return(group)
              end
            end

            context 'when trial can be applied' do
              before do
                expect_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
                  expect(service).to receive(:execute).with(apply_trial_params).and_return({ success: true })
                end
              end

              context 'with redirection to projects page' do
                it { is_expected.to redirect_to(new_users_sign_up_project_path(namespace_id: group.id, trial: false, trial_onboarding_flow: true)) }
              end
            end

            context 'when failing to apply trial' do
              before do
                expect_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
                  expect(service).to receive(:execute).with(apply_trial_params).and_return({ success: false })
                end
              end

              it { is_expected.to render_template(:new) }
            end
          end

          context 'when not in the trial onboarding - registration_onboarding_flow' do
            let_it_be(:group) { create(:group) }

            context 'when trial_during_signup - trial_during_signup_flow' do
              let_it_be(:glm_params) { { glm_source: 'gitlab.com', glm_content: 'content' } }
              let_it_be(:trial_form_params) do
                {
                  trial: 'true',
                  company_name: 'ACME',
                  company_size: '1-99',
                  phone_number: '11111111',
                  country: 'Norway'
                }
              end

              let_it_be(:trial_user_params) do
                {
                  work_email: user.email,
                  first_name: user.first_name,
                  last_name: user.last_name,
                  uid: user.id,
                  setup_for_company: nil,
                  skip_email_confirmation: true,
                  gitlab_com_trial: true,
                  provider: 'gitlab',
                  newsletter_segment: user.email_opted_in
                }
              end

              let_it_be(:trial_params) do
                {
                  trial_user: ActionController::Parameters.new(trial_form_params.except(:trial).merge(trial_user_params)).permit!
                }
              end

              let_it_be(:apply_trial_params) do
                {
                  uid: user.id,
                  trial_user: ActionController::Parameters.new(
                    {
                      glm_source: 'gitlab.com',
                      glm_content: 'content',
                      namespace_id: group.id,
                      gitlab_com_trial: true,
                      sync_to_gl: true
                    }
                  ).permit!
                }
              end

              context 'when a user chooses a trial - create_lead_and_apply_trial_flow' do
                context 'when successfully creating a lead and applying trial' do
                  before do
                    expect_next_instance_of(Groups::CreateService) do |service|
                      expect(service).to receive(:execute).and_return(group)
                    end
                    expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |service|
                      expect(service).to receive(:execute).with(trial_params).and_return(success: true)
                    end
                    expect_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
                      expect(service).to receive(:execute).with(apply_trial_params).and_return({ success: true })
                    end
                  end

                  context 'with redirection to projects page' do
                    it { is_expected.to redirect_to(new_users_sign_up_project_path(namespace_id: group.id, trial: true)) }
                  end

                  it 'tracks for the combined_registration experiment', :experiment do
                    expect(experiment(:combined_registration)).to track(:create_group, namespace: an_instance_of(Group)).on_next_instance
                    subject
                  end
                end

                context 'when failing to create a lead and apply trial' do
                  before do
                    expect_next_instance_of(Groups::CreateService) do |service|
                      expect(service).to receive(:execute).and_return(group)
                    end
                    expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |service|
                      expect(service).to receive(:execute).with(trial_params).and_return(success: false)
                    end
                  end

                  it { is_expected.to render_template(:new) }
                end
              end

              context 'when user chooses no trial' do
                let_it_be(:trial_form_params) { { trial: 'false' } }

                it 'redirects user to projects page' do
                  expect_next_instance_of(Groups::CreateService) do |service|
                    expect(service).to receive(:execute).and_return(group)
                  end

                  expect(post_create).to redirect_to(new_users_sign_up_project_path(namespace_id: group.id, trial: false))
                end

                it 'does not call trial creation methods' do
                  expect(controller).not_to receive(:create_lead)
                  expect(controller).not_to receive(:apply_trial)

                  post_create
                end
              end
            end
          end
        end

        context 'when the group cannot be created' do
          let(:group_params) { { name: '', path: '' } }

          it 'does not create a group', :aggregate_failures do
            expect { post_create }.not_to change { Group.count }
            expect(assigns(:group).errors).not_to be_blank
          end

          it 'does not call call the successful flow' do
            expect(controller).not_to receive(:create_successful_flow)

            post_create
          end

          it { is_expected.to have_gitlab_http_status(:ok) }
          it { is_expected.to render_template(:new) }
        end
      end

      context 'when not on .com' do
        let(:com) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end
end
