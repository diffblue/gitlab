# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin, :skip_live_env, except: { job: 'review-qa-*' },
                                                                 product_group: :billing_and_subscription_management do
    describe 'Purchase' do
      describe 'User Registration' do
        let(:group) do
          Resource::Group.fabricate_via_api!
        end

        let(:user) do
          Resource::User.init do |user|
            user.first_name = 'QA'
            user.last_name = 'Test'
            user.username = "qa-test-#{SecureRandom.hex(3)}"
            user.hard_delete_on_api_removal = true
          end
        end

        before do
          # Enable sign-ups
          Runtime::ApplicationSettings.set_application_settings(signup_enabled: true)
          Runtime::ApplicationSettings.set_application_settings(require_admin_approval_after_user_signup: true)

          # Register the new user through the registration page
          Gitlab::Page::Main::SignUp.perform do |sign_up|
            sign_up.visit
            sign_up.register_user(user)
          end

          Flow::UserOnboarding.onboard_user(wait: 0)
        end

        after do
          # Restore what the signup_enabled setting was before this test was run
          Runtime::ApplicationSettings.restore_application_settings(:signup_enabled)

          user.remove_via_api!
          group.remove_via_api!
        rescue Resource::ApiFabricator::ResourceNotDeletedError
          # ignore and leave for other cleanup tasks.
          # sometimes `group.remove_api!` fails with error:
          #   could not be deleted (400): `{"message":"Group has been already marked for deletion"}`
        end

        context 'when adding and removing a group member' do
          it 'consumes a seat on the license', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347617' do
            Flow::Login.sign_in_as_admin

            # Save the number of users as stated by the license
            users_in_subscription = Gitlab::Page::Admin::Subscription.perform do |subscription|
              subscription.visit
              subscription.users_in_subscription
            end.tr(',', '') # sanitize the value when returned as 10,000

            # Save the number of users active on the instance as reported by GitLab
            users_in_license = Gitlab::Page::Admin::Dashboard.perform do |users|
              users.visit
              users.users_in_license
            end.tr(',', '') # sanitize the value when returned as 10,000

            expect(users_in_subscription).to eq(users_in_license)

            billable_users = Gitlab::Page::Admin::Dashboard.perform(&:billable_users)

            # Activate the new user
            user.reload! && user.approve! # first reload the API resource to fetch the ID, then approve

            Gitlab::Page::Admin::Dashboard.perform do |dashboard|
              dashboard.visit

              # Validate billable users has not changed after approval
              expect(dashboard.billable_users).to eq(billable_users)

              group.add_member(user) # add the user to the group

              dashboard.visit # reload

              # Validate billable users incremented by 1
              expect(dashboard.billable_users.to_i).to eq(billable_users.to_i + 1)

              group.remove_member(user) # remove the user from the group

              dashboard.visit # reload

              # Validate billable users equals the original amount
              expect(dashboard.billable_users).to eq(billable_users)
            end
          end
        end
      end
    end
  end
end
