# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User registration", :js, :saas do
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }

  before do
    stub_feature_flags(
      # This is an experiment that we're trying to clean up at the same time as
      # adding these new registration flows:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/350278
      bypass_registration: true,

      # This is an "experiment" that's not been cleaned up and is over a year old:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/255170
      user_other_role_details: true,

      # This is an experiment that we want to clean up, but can't yet because of
      # query limit concerns:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/350754
      combined_registration: true,

      # This is the feature flag for the new registration flows where the user is
      # required to provide company details when registering for their company in
      # both the standard registration and trial flows.
      about_your_company_registration_flow: true
    )

    # The groups_and_projects_controller (on `click_on 'Create project'`) is over
    # the query limit threshold, so we have to adjust it.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/338737
    stub_const('Gitlab::QueryLimiting::Transaction::THRESHOLD', 270)

    # Various actions in this flow can trigger a request off to the customerApp
    # to log the lead data generated in the registration flows.
    stub_request(:post, Gitlab::SubscriptionPortal.default_subscriptions_url).to_return(
      status: 200,
      body: '',
      headers: {}
    )

    sign_in user
    visit users_sign_up_welcome_path
  end

  describe "using the standard flow" do
    it "presents the initial welcome step" do
      expect(page).to have_content('Welcome to GitLab')

      select 'Other', from: 'user_role'

      # This is behind the user_other_role_details feature flag.
      fill_in 'user_other_role', with: 'My role'

      select 'A different reason', from: 'user_registration_objective'
      fill_in 'jobs_to_be_done_other', with: 'My reason'
    end

    context "just for me" do
      before do
        choose 'Just me'
        check 'I\'d like to receive updates about GitLab via email'
      end

      context "wanting to join a project" do
        before do
          choose 'Join a project'
          click_on 'Continue'
        end

        it "takes me to my dashboard" do
          expect(page).to have_content 'This user doesn\'t have any personal projects'
        end

        it "signs me up for email updates" do
          expect(user.reload).to be_email_opted_in
        end
      end

      context "wanting to create a project" do
        # This flow is behind the combined_registration feature flag.

        before do
          choose 'Create a new project'
          click_on 'Continue'
        end

        it "creates my new group and project without a trial" do
          fill_in 'group_name', with: 'Test Group'
          fill_in 'blank_project_name', with: 'Test Project'

          click_on 'Create project'

          # We end up in the continuous onboarding flow here...
          expect(page).to have_content 'Get started with GitLab'

          # So have to verify the newly created project by navigating to our projects...
          visit projects_path

          # Where we have two projects, one being part of continuous onboarding.
          expect(page).to have_content 'Test Group / Test Project'
          expect(page).to have_content 'Test Group / Learn GitLab'
        end

        it "imports my existing project without a trial" do
          click_on 'Import'
          fill_in 'import_group_name', with: 'Test Group'
          click_on 'GitHub'

          expect(page).to have_content <<~MESSAGE.tr("\n", ' ')
            To connect GitHub repositories, you first need to authorize
            GitLab to access the list of your GitHub repositories.
          MESSAGE
        end
      end
    end

    context "for my company" do
      before do
        choose 'My company or team'
      end

      context "wanting to join a project" do
        before do
          choose 'Join a project'
          click_on 'Continue'
        end

        it "takes me to my dashboard" do
          expect(page).to have_content 'This user doesn\'t have any personal projects'
        end
      end

      context "wanting to create a project" do
        # This flow is behind the combined_registration feature flag.

        before do
          choose 'Create a new project'
          click_on 'Continue'
        end

        it "prompts for details about my company" do
          expect(page).to have_content 'About your company'

          fill_in 'company_name', with: 'Test Company'
          select '1 - 99', from: 'company_size'
          select 'United States of America', from: 'country'
          select 'Florida', from: 'state'
          fill_in 'phone_number', with: '+1234567890'
          fill_in 'website_url', with: 'https://gitlab.com'
        end

        context "and opting into a trial" do
          before do
            click_button class: 'gl-toggle'

            expect_next(GitlabSubscriptions::CreateLeadService).to receive(:execute).with(
              trial_user: ActionController::Parameters.new(
                company_name: '',
                company_size: '',
                phone_number: '',
                country: '',
                website_url: '',
                work_email: user.email,
                uid: user.id,
                setup_for_company: true,
                skip_email_confirmation: true,
                gitlab_com_trial: true,
                provider: 'gitlab',
                newsletter_segment: true
              ).permit!
            ).and_return(success: true)

            click_on 'Continue'
          end

          it "creates my new group and project with a trial" do
            pending

            fill_in 'group_name', with: 'Test Group'
            fill_in 'blank_project_name', with: 'Test Project'

            expect_next(GitlabSubscriptions::CreateLeadService).to receive(:execute).with(
              uid: user.id,
              trial_user:
                ActionController::Parameters.new(
                  namespace_id: Namespace.maximum(:id).to_i + 1,
                  trial_entity: 'company',
                  gitlab_com_trial: true,
                  sync_to_gl: true
                ).permit!
            ).and_return(success: true)

            click_on 'Create project'

            expect(page).to have_content 'Get started with GitLab'
          end
        end

        context "without a trial" do
          before do
            click_on 'Continue'
          end

          it "creates my new group and project without a trial" do
            pending

            fill_in 'group_name', with: 'Test Group'
            fill_in 'blank_project_name', with: 'Test Project'
            click_on 'Create project'

            # We end up in the continuous onboarding flow here...
            expect(page).to have_content 'Get started with GitLab'

            # So have to verify the newly created project by navigating to our projects...
            visit projects_path

            # Where we have two projects, one being part of continuous onboarding.
            expect(page).to have_content 'Test Group / Test Project'
            expect(page).to have_content 'Test Group / Learn GitLab'
          end
        end
      end
    end
  end
end
