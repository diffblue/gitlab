# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::WelcomeController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }

  describe '#continuous_onboarding_getting_started' do
    let_it_be(:project) { create(:project, group: group) }

    subject(:continuous_onboarding_getting_started) do
      get :continuous_onboarding_getting_started, params: { project_id: project.id }
    end

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'with an owner user signed in' do
      before do
        sign_in(user)
        project.group.add_owner(user)
      end

      it { is_expected.to render_template(:continuous_onboarding_getting_started) }
    end

    context 'with a non-owner user signed in' do
      before do
        sign_in(user)
        project.group.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end

  describe '#trial_getting_started' do
    let_it_be(:project) { create(:project, group: group) }

    subject(:trial_getting_started) do
      get :trial_getting_started, params: { learn_gitlab_project_id: project.id }
    end

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'with an owner user signed in' do
      before do
        sign_in(user)
        project.group.add_owner(user)
      end

      it { is_expected.to render_template(:trial_getting_started) }
    end

    context 'with a non-owner user signed' do
      before do
        sign_in(user)
        project.group.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end

  describe '#trial_onboarding_board' do
    let_it_be(:project) { create(:project, group: group) }

    subject(:trial_onboarding_board) do
      get :trial_onboarding_board, params: { learn_gitlab_project_id: project.id }
    end

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_session_path }
    end

    context 'with a non-owner user signin' do
      before do
        sign_in(user)
        project.group.add_maintainer(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'with an owner user signs in' do
      before do
        sign_in(user)
        project.group.add_owner(user)
      end

      context 'gitlab onboarding project is not imported yet' do
        it 'redirects to the boards path' do
          subject

          is_expected.to redirect_to(project_boards_path(project))
        end
      end

      context 'gitlab onboarding project is imported yet' do
        let_it_be(:board) { create(:board, project: project, name: EE::Registrations::WelcomeController::TRIAL_ONBOARDING_BOARD_NAME) }

        it 'redirects to the board path' do
          subject

          is_expected.to redirect_to(project_board_path(project, board))
        end
      end
    end
  end

  describe '#update' do
    let(:setup_for_company) { 'false' }
    let(:email_opted_in) { '0' }

    subject(:update) do
      patch :update, params: {
        user: {
          role: 'software_developer',
          setup_for_company: setup_for_company,
          email_opted_in: email_opted_in
        }
      }
    end

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_registration_path }
    end

    context 'with a signed in user' do
      before do
        sign_in(user)
      end

      context 'email updates' do
        context 'when not on gitlab.com' do
          before do
            allow(::Gitlab).to receive(:com?).and_return(false)
          end

          context 'when the user opted in' do
            let(:email_opted_in) { '1' }

            it 'sets the email_opted_in field' do
              subject

              expect(controller.current_user).to be_email_opted_in
            end
          end

          context 'when the user opted out' do
            it 'sets the email_opted_in field' do
              subject

              expect(controller.current_user).not_to be_email_opted_in
            end
          end
        end

        context 'when on gitlab.com' do
          before do
            allow(::Gitlab).to receive(:com?).and_return(true)
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
        context 'when signup_onboarding is not enabled' do
          before do
            allow(controller.helpers).to receive(:signup_onboarding_enabled?).and_return(false)
          end

          it { is_expected.to redirect_to dashboard_projects_path }
        end

        context 'when signup_onboarding is enabled' do
          before do
            allow(controller.helpers).to receive(:signup_onboarding_enabled?).and_return(true)
          end

          context 'and force_company_trial experiment is candidate' do
            let(:setup_for_company) { 'true' }

            before do
              stub_experiments(force_company_trial: :candidate)
            end

            it { is_expected.to redirect_to new_users_sign_up_group_path(trial: true) }
          end

          it { is_expected.to redirect_to new_users_sign_up_group_path }

          context 'when in subscription flow' do
            before do
              allow(controller.helpers).to receive(:in_subscription_flow?).and_return(true)
            end

            it { is_expected.not_to redirect_to new_users_sign_up_group_path }
          end

          context 'when in invitation flow' do
            before do
              allow(controller.helpers).to receive(:user_has_memberships?).and_return(true)
            end

            it { is_expected.not_to redirect_to new_users_sign_up_group_path }
          end

          context 'when in trial flow' do
            before do
              allow(controller.helpers).to receive(:in_trial_flow?).and_return(true)
            end

            it { is_expected.not_to redirect_to new_users_sign_up_group_path }
          end
        end
      end
    end
  end
end
