# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::WelcomeController, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }

  describe '#show' do
    let(:show_params) { {} }

    subject(:get_show) { get :show, params: show_params }

    before do
      sign_in(user)
    end

    it 'tracks render event' do
      get_show

      expect_snowplow_event(
        category: 'registrations:welcome:show',
        action: 'render',
        user: user,
        label: 'free_registration'
      )
    end

    context 'when in invitation flow' do
      before do
        create(:group_member, source: group, user: user)
      end

      it 'tracks render event' do
        get_show

        expect_snowplow_event(
          category: 'registrations:welcome:show',
          action: 'render',
          user: user,
          label: 'invite_registration'
        )
      end
    end

    context 'when in trial flow', :saas do
      let(:show_params) { { trial: 'true' } }

      it 'tracks render event' do
        get_show

        expect_snowplow_event(
          category: 'registrations:welcome:show',
          action: 'render',
          user: user,
          label: 'trial_registration'
        )
      end
    end

    context 'when completed welcome step' do
      let_it_be(:user) { create(:user, setup_for_company: true) }

      it 'does not track render event' do
        get_show

        expect_no_snowplow_event(
          category: 'registrations:welcome:show',
          action: 'render',
          user: user,
          label: 'free_registration'
        )
      end
    end
  end

  describe '#update' do
    let(:setup_for_company) { 'false' }
    let(:email_opted_in) { '0' }
    let(:joining_project) { 'false' }
    let(:extra_params) { {} }
    let(:update_params) do
      {
        user: {
          role: 'software_developer',
          setup_for_company: setup_for_company,
          email_opted_in: email_opted_in,
          registration_objective: 'code_storage'
        },
        joining_project: joining_project,
        jobs_to_be_done_other: '_jobs_to_be_done_other_',
        glm_source: 'some_source',
        glm_content: 'some_content'
      }.merge(extra_params)
    end

    subject(:patch_update) { patch :update, params: update_params }

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_registration_path }
    end

    context 'with a signed in user' do
      before do
        sign_in(user)
      end

      context 'with email updates' do
        context 'when not on gitlab.com' do
          context 'when the user opted in' do
            let(:email_opted_in) { '1' }

            it 'sets the email_opted_in field' do
              subject

              expect(controller.current_user).to be_email_opted_in
            end

            it 'does not set the rest of the email_opted_in fields' do
              subject

              expect(controller.current_user)
                .to have_attributes(email_opted_in_ip: nil, email_opted_in_source: '', email_opted_in_at: nil)
            end
          end

          context 'when the user opted out' do
            let(:setup_for_company) { 'true' }

            it 'sets the email_opted_in field' do
              subject

              expect(controller.current_user).not_to be_email_opted_in
            end
          end
        end

        context 'when on gitlab.com', :saas do
          context 'when registration_objective field is provided' do
            it 'sets the registration_objective' do
              subject

              expect(controller.current_user.registration_objective).to eq('code_storage')
            end
          end

          context 'when setup for company is false' do
            context 'when the user opted in' do
              let(:email_opted_in) { '1' }

              it 'sets the email_opted_in fields' do
                subject

                expect(controller.current_user).to have_attributes(
                  email_opted_in: be_truthy,
                  email_opted_in_ip: be_present,
                  email_opted_in_source: eq('GitLab.com'),
                  email_opted_in_at: be_present
                )
              end
            end

            context 'when user opted out' do
              let(:email_opted_in) { '0' }

              it 'does not set the rest of the email_opted_in fields' do
                subject

                expect(controller.current_user).to have_attributes(
                  email_opted_in: false,
                  email_opted_in_ip: nil,
                  email_opted_in_source: "",
                  email_opted_in_at: nil
                )
              end
            end
          end

          context 'when setup for company is true' do
            let(:setup_for_company) { 'true' }

            it 'sets email_opted_in fields' do
              subject

              expect(controller.current_user).to have_attributes(
                email_opted_in: be_truthy,
                email_opted_in_ip: be_present,
                email_opted_in_source: eq('GitLab.com'),
                email_opted_in_at: be_present
              )
            end
          end
        end
      end

      describe 'redirection' do
        context 'when onboarding is not enabled' do
          it { is_expected.to redirect_to dashboard_projects_path }

          it 'tracks successful submission event' do
            patch_update

            expect_snowplow_event(
              category: 'registrations:welcome:update',
              action: 'successfully_submitted_form',
              user: user,
              label: 'free_registration'
            )
          end
        end

        context 'when onboarding is enabled', :saas do
          let(:user) do
            create(:user, onboarding_in_progress: true).tap do |record|
              create(:user_detail, user: record, onboarding_step_url: '_url_')
            end
          end

          before do
            stub_ee_application_setting(should_check_namespace_plan: true)
          end

          context 'when joining_project is "true"' do
            let(:joining_project) { 'true' }

            specify do
              patch_update
              user.reload

              expect(user.onboarding_in_progress).to be_falsey
              expect(user.user_detail.onboarding_step_url).to be_nil
              expect(response).to redirect_to dashboard_projects_path
            end
          end

          context 'when joining_project is "false"' do
            context 'with group and project creation' do
              specify do
                patch_update
                user.reload
                path = new_users_sign_up_group_path

                expect(user.onboarding_in_progress).to be_truthy
                expect(user.user_detail.onboarding_step_url).to eq(path)
                expect(response).to redirect_to path
              end
            end
          end

          context 'when eligible for iterable trigger' do
            before do
              allow_next_instance_of(::Onboarding::Status) do |instance|
                allow(instance).to receive(:eligible_for_iterable_trigger?).and_return(true)
              end
            end

            it 'initiates iterable trigger creation' do
              expect(::Onboarding::CreateIterableTriggerWorker).to receive(:perform_async)

              patch_update
            end
          end

          context 'when not eligible for iterable trigger' do
            before do
              allow_next_instance_of(::Onboarding::Status) do |instance|
                allow(instance).to receive(:eligible_for_iterable_trigger?).and_return(false)
              end
            end

            it 'does not initiate iterable trigger creation' do
              expect(::Onboarding::CreateIterableTriggerWorker).not_to receive(:perform_async)

              patch_update
            end
          end

          context 'when setup_for_company is "true"' do
            let(:setup_for_company) { 'true' }
            let(:trial_concerns) { {} }
            let(:redirect_path) { new_users_sign_up_company_path(expected_params) }
            let(:expected_params) do
              {
                registration_objective: 'code_storage',
                role: 'software_developer',
                jobs_to_be_done_other: '_jobs_to_be_done_other_',
                glm_source: 'some_source',
                glm_content: 'some_content'
              }.merge(trial_concerns)
            end

            before do
              patch_update
            end

            it 'redirects to the company path and stores the url' do
              user.reload

              expect(user.onboarding_in_progress).to be_truthy
              expect(user.user_detail.onboarding_step_url).to eq(redirect_path)
              expect(response).to redirect_to redirect_path
            end

            context 'with trial param sent with update' do
              let(:trial_concerns) { extra_params }

              context 'with trial as true' do
                let(:extra_params) { { trial: 'true' } }

                it 'redirects to the company path with trial param' do
                  expect(response).to redirect_to redirect_path
                end
              end

              context 'with trial as not true' do
                let(:extra_params) { { trial: 'false' } }

                it 'does not include the trial param in the redirect path' do
                  expect(response).to redirect_to redirect_path
                end
              end
            end
          end

          context 'when setup_for_company is "false"' do
            let(:setup_for_company) { 'false' }

            specify do
              patch_update
              user.reload
              path = new_users_sign_up_group_path

              expect(user.onboarding_in_progress).to be_truthy
              expect(user.user_detail.onboarding_step_url).to eq(path)
              expect(response).to redirect_to path
            end

            context 'when trial is true' do
              let(:extra_params) { { trial: 'true' } }
              let(:expected_params) do
                {
                  registration_objective: 'code_storage',
                  role: 'software_developer',
                  jobs_to_be_done_other: '_jobs_to_be_done_other_',
                  glm_source: 'some_source',
                  glm_content: 'some_content',
                  trial: 'true'
                }
              end

              specify do
                patch_update
                user.reload
                path = new_users_sign_up_company_path(expected_params)

                expect(user.onboarding_in_progress).to be_truthy
                expect(user.user_detail.onboarding_step_url).to eq(path)
                expect(response).to redirect_to path
              end
            end

            context 'when trial is false' do
              let(:extra_params) { { trial: 'false' } }
              let(:expected_params) do
                {
                  registration_objective: 'code_storage',
                  role: 'software_developer',
                  jobs_to_be_done_other: '_jobs_to_be_done_other_',
                  glm_source: 'some_source',
                  glm_content: 'some_content',
                  trial: 'false'
                }
              end

              specify do
                patch_update
                user.reload
                path = new_users_sign_up_group_path

                expect(user.onboarding_in_progress).to be_truthy
                expect(user.user_detail.onboarding_step_url).to eq(path)
                expect(response).to redirect_to path
              end
            end
          end

          context 'when in subscription flow' do
            subject { patch :update, params: update_params, session: { user_return_to: new_subscriptions_path } }

            it { is_expected.not_to redirect_to new_users_sign_up_group_path }
          end

          context 'when in invitation flow' do
            before do
              create(:group_member, source: group, user: user)
            end

            it { is_expected.not_to redirect_to new_users_sign_up_group_path }

            it 'tracks successful submission event' do
              patch_update

              expect_snowplow_event(
                category: 'registrations:welcome:update',
                action: 'successfully_submitted_form',
                user: user,
                label: 'invite_registration'
              )
            end
          end

          context 'when in trial flow' do
            let(:extra_params) { { trial: 'true' } }

            it { is_expected.not_to redirect_to new_users_sign_up_group_path }

            it 'tracks successful submission event' do
              patch_update

              expect_snowplow_event(
                category: 'registrations:welcome:update',
                action: 'successfully_submitted_form',
                user: user,
                label: 'trial_registration'
              )
            end

            context 'when stored company path' do
              let(:stored_path) { new_users_sign_up_company_path }

              before do
                controller.store_location_for(:user, stored_path)
              end

              specify do
                patch_update
                user.reload

                path = ::Gitlab::Utils.add_url_parameters(
                  stored_path, {
                    glm_content: 'some_content',
                    glm_source: 'some_source',
                    jobs_to_be_done_other: '_jobs_to_be_done_other_',
                    registration_objective: 'code_storage',
                    role: 'software_developer'
                  }.merge(extra_params)
                )

                expect(user.onboarding_in_progress).to be_truthy
                expect(user.user_detail.onboarding_step_url).to eq(path)
                expect(response).to redirect_to path
              end
            end
          end
        end

        context 'when failed request' do
          subject(:patch_update) { patch :update, params: { user: { role: 'software_developer' } } }

          before do
            allow_next_instance_of(::Users::SignupService) do |service|
              allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'failed'))
            end
          end

          it 'does not track submission event' do
            patch_update

            expect_no_snowplow_event(
              category: 'registrations:welcome:update',
              action: 'successfully_submitted_form',
              user: user,
              label: 'free_registration'
            )
          end
        end
      end
    end
  end
end
