# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging }, product_group: :purchase do
    describe 'Purchase' do
      let(:api_client) { Runtime::API::Client.as_admin }
      let(:user) do
        Resource::User.fabricate_via_api! do |user|
          user.email = "test-user-#{SecureRandom.hex(4)}@gitlab.com"
          user.api_client = api_client
          user.hard_delete_on_api_removal = true
        end
      end

      let(:group_for_trial) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "test-group-fulfillment#{SecureRandom.hex(4)}"
          sandbox.api_client = api_client
        end
      end

      before do
        Flow::Login.sign_in(as: user)
        group_for_trial.visit!
      end

      after do
        user.remove_via_api!
      end

      describe 'starts a free trial' do
        context 'when on about page with multiple eligible namespaces' do
          let!(:group) do
            Resource::Sandbox.fabricate! do |sandbox|
              sandbox.path = "test-group-fulfillment#{SecureRandom.hex(4)}"
              sandbox.api_client = api_client
            end
          end

          before do
            Runtime::Browser.visit(:about, Chemlab::Vendor::GitlabHandbook::Page::About)

            Chemlab::Vendor::GitlabHandbook::Page::About.perform(&:get_free_trial)

            Page::Trials::New.perform(&:visit)
          end

          after do
            group.remove_via_api!
          end

          it 'registers for a new trial', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347671', quarantine: {
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/385866',
            type: :stale
          } do
            register_for_trial

            Page::Alert::FreeTrial.perform do |free_trial_alert|
              expect(free_trial_alert.trial_activated_message).to have_text('Congratulations, your free trial is activated')
            end

            Page::Group::Menu.perform(&:go_to_billing)

            Gitlab::Page::Group::Settings::Billing.perform do |billing|
              expect do
                billing.billing_plan_header
              end.to eventually_include("#{group_for_trial.path} is currently using the Ultimate SaaS Trial Plan").within(max_duration: 120, max_attempts: 60, reload_page: page)
            end
          end
        end

        context 'when on billing page with only one eligible namespace' do
          before do
            group_for_trial.visit!
            Page::Group::Menu.perform(&:go_to_billing)
          end

          it 'registers for a new trial', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349163' do
            Gitlab::Page::Group::Settings::Billing.perform(&:start_your_free_trial)
            register_for_trial(skip_select: true)

            Page::Alert::FreeTrial.perform do |free_trial_alert|
              expect(free_trial_alert.trial_activated_message).to have_text('Congratulations, your free trial is activated')
            end

            Page::Group::Menu.perform(&:go_to_billing)

            Gitlab::Page::Group::Settings::Billing.perform do |billing|
              expect do
                billing.billing_plan_header
              end.to eventually_include("#{group_for_trial.path} is currently using the Ultimate SaaS Trial Plan").within(max_duration: 120, max_attempts: 60, reload_page: page)
            end
          end
        end
      end

      private

      def customer_trial_info
        {
          company_name: 'QA Test Company',
          number_of_employees: '500 - 1,999',
          telephone_number: '555-555-5555',
          country: 'United States of America',
          state: 'CA'
        }
      end

      def register_for_trial(skip_select: false)
        Page::Trials::New.perform do |new|
          # setter
          new.company_name = customer_trial_info[:company_name]
          new.number_of_employees = customer_trial_info[:number_of_employees]
          new.country = customer_trial_info[:country]
          new.telephone_number = customer_trial_info[:telephone_number]
          new.state = customer_trial_info[:state]

          new.continue
        end

        unless skip_select
          Page::Trials::Select.perform do |select|
            select.subscription_for = group_for_trial.path
            select.trial_company
            select.start_your_free_trial
          end
        end
      end
    end
  end
end
