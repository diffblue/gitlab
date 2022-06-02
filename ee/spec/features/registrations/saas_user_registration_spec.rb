# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User registration", :js, :saas do
  include AfterNextHelpers

  let(:service_with_success) do
    instance_double(GitlabSubscriptions::CreateTrialOrLeadService, execute: ServiceResponse.success)
  end

  before do
    stub_feature_flags(
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

    stub_application_setting(
      # Saas doesn't require admin approval.
      require_admin_approval_after_user_signup: false
    )

    # The groups_and_projects_controller (on `click_on 'Create project'`) is over
    # the query limit threshold, so we have to adjust it.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/338737
    stub_const('Gitlab::QueryLimiting::Transaction::THRESHOLD', 272)
  end

  def fill_in_sign_up_form(user)
    fill_in 'First name', with: user.first_name
    fill_in 'Last name', with: user.last_name
    fill_in 'Username', with: user.username
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
  end

  def fill_in_welcome_form
    select 'Other', from: 'user_role'
    fill_in 'What is your job title? (optional)', with: 'My role' # behind the user_other_role_details feature flag.

    select 'A different reason', from: 'user_registration_objective'
    fill_in 'Why are you signing up? (optional)', with: 'My reason'
  end

  def fill_in_company_form
    fill_in 'company_name', with: 'Test Company'
    select '1 - 99', from: 'company_size'
    select 'United States of America', from: 'country'
    select 'Florida', from: 'state'
    fill_in 'phone_number', with: '+1234567890'
    fill_in 'website_url', with: 'https://gitlab.com'
  end

  describe "when accepting an invite" do
    let_it_be(:user) { build(:user, name: 'Invited User') }
    let_it_be(:owner) { create(:user, name: 'John Doe') }
    let_it_be(:group) { create(:group, name: 'Test Group') }

    before do
      group.add_owner(owner)

      invitation = create(:group_member, :invited, :developer,
        invite_email: user.email,
        group: group,
        created_by: owner
      )
      visit invite_path(invitation.raw_invite_token, invite_type: Emails::Members::INITIAL_INVITE)

      fill_in_sign_up_form(user)
      click_on 'Register'
    end

    it "doesn't ask me what I would like to do" do
      expect(page).to have_content('Welcome to GitLab, Invited!')
      expect(page).not_to have_content('What would you like to do?')
    end

    it "sends me to the group activity page" do
      fill_in_welcome_form
      click_on 'Get started!'

      expect(page).to have_current_path(activity_group_path(group), ignore_query: true)
      expect(page).to have_content('You have been granted Developer access to group Test Group')
    end
  end

  describe "using the standard flow" do
    let_it_be(:user) { create(:user, name: 'Onboarding User') }

    before do
      sign_in user
      visit users_sign_up_welcome_path
    end

    it "presents the initial welcome step" do
      expect(page).to have_content('Welcome to GitLab, Onboarding!')

      fill_in_welcome_form
    end

    context "just for me" do
      before do
        fill_in_welcome_form
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
        fill_in_welcome_form
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
        # This flow is behind the combined_registration and the
        # about_your_company_registration_flow feature flags.

        before do
          choose 'Create a new project'
          click_on 'Continue'
        end

        it "prompts for details about my company" do
          expect(page).to have_content 'About your company'

          fill_in_company_form
        end

        context "and opting into a trial" do
          before do
            fill_in_company_form
            click_button class: 'gl-toggle'

            expect(GitlabSubscriptions::CreateTrialOrLeadService).to receive(:new).with(
              user: user,
              params: ActionController::Parameters.new(
                company_name: 'Test Company',
                company_size: '1-99',
                phone_number: '+1234567890',
                country: 'US',
                state: 'FL',
                website_url: 'https://gitlab.com',
                trial: 'true',
                # these are the passed through params
                role: 'other',
                other_role: 'My role',
                registration_objective: 'other',
                jobs_to_be_done_other: 'My reason'
              ).permit!
            ).and_return(service_with_success)

            click_on 'Continue'
          end

          it "creates my new group and project with a trial" do
            fill_in 'group_name', with: 'Test Group'
            fill_in 'blank_project_name', with: 'Test Project'

            expect_next(GitlabSubscriptions::ApplyTrialService).to receive(:execute).with({
              uid: user.id,
              trial_user: hash_including(
                namespace_id: anything,
                gitlab_com_trial: true,
                sync_to_gl: true
              )
            }).and_return(success: true)

            click_on 'Create project'

            expect(page).to have_content 'Get started with GitLab'
          end
        end

        context "without a trial" do
          before do
            fill_in_company_form

            expect(GitlabSubscriptions::CreateTrialOrLeadService).to receive(:new).with(
              user: user,
              params: hash_including(
                trial: 'false',
                # these are the passed through params
                role: 'other',
                other_role: 'My role',
                registration_objective: 'other',
                jobs_to_be_done_other: 'My reason'
              )
            ).and_return(service_with_success)

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
        end
      end
    end
  end
end
