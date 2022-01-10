# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging } do
    describe 'Purchase' do
      let(:api_client) { Runtime::API::Client.as_admin }
      let(:user) do
        Resource::User.fabricate_via_api! do |user|
          user.email = "gitlab-qa+#{SecureRandom.hex(2)}@gitlab.com"
          user.api_client = api_client
          user.hard_delete_on_api_removal = true
        end
      end

      let(:group1) do
        Resource::Sandbox.fabricate! do |sandbox|
          sandbox.path = "gitlab-qa-group-#{SecureRandom.hex(4)}"
          sandbox.api_client = api_client
        end
      end

      before do
        group1.add_member(user, Resource::Members::AccessLevel::OWNER)
      end

      after do
        user.remove_via_api!
      end

      describe 'starts a free trial' do
        context 'when on about page with multiple eligible namespaces' do
          let(:group2) do
            Resource::Sandbox.fabricate! do |sandbox|
              sandbox.path = "gitlab-qa-group-#{SecureRandom.hex(4)}"
              sandbox.api_client = api_client
            end
          end

          before do
            group2.add_member(user, Resource::Members::AccessLevel::OWNER)

            Flow::Login.sign_in(as: user)

            Runtime::Browser.visit(:about, Chemlab::Vendor::GitlabHandbook::Page::About)

            Chemlab::Vendor::GitlabHandbook::Page::About.perform(&:get_free_trial)

            Page::Trials::New.perform(&:visit)
          end

          it 'registers for a new trial', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347671' do
            register_for_trial

            Page::Alert::FreeTrial.perform do |free_trial_alert|
              expect(free_trial_alert.trial_activated_message).to have_text('Congratulations, your free trial is activated')
            end

            Page::Group::Menu.perform(&:go_to_billing)

            Gitlab::Page::Group::Settings::Billing.perform do |billing|
              expect do
                billing.billing_plan_header
              end.to eventually_include("#{group1.path} is currently using the Ultimate SaaS Trial Plan").within(max_duration: 120, max_attempts: 60, reload_page: page)
            end
          end
        end

        context 'when on billing page with only one eligible namespace' do
          before do
            Flow::Login.sign_in(as: user)
            group1.visit!
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
              end.to eventually_include("#{group1.path} is currently using the Ultimate SaaS Trial Plan").within(max_duration: 120, max_attempts: 60, reload_page: page)
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
          country: 'United States of America'
        }
      end

      def register_for_trial(skip_select: false)
        Page::Trials::New.perform do |new|
          # setter
          new.company_name = customer_trial_info[:company_name]
          new.number_of_employees = customer_trial_info[:number_of_employees]
          new.telephone_number = customer_trial_info[:telephone_number]
          new.country = customer_trial_info[:country]

          new.continue
        end

        unless skip_select
          Page::Trials::Select.perform do |select|
            select.subscription_for = group1.path
            select.trial_company
            select.start_your_free_trial
          end
        end
      end
    end
  end
end
