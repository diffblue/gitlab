# frozen_string_literal: true

module QA
  RSpec.describe 'Fulfillment', :requires_admin, only: { subdomain: :staging } do
    describe 'Purchase' do
      let(:user) do
        Resource::User.fabricate_via_api! do |user|
          user.email = "gitlab-qa+#{SecureRandom.hex(2)}@gitlab.com"
          user.api_client = Runtime::API::Client.as_admin
          user.hard_delete_on_api_removal = true
        end
      end

      let(:last_name) { 'Test' }
      let(:company_name) { 'QA Test Company' }
      let(:number_of_employees) { '500 - 1,999' }
      let(:telephone_number) { '555-555-5555' }
      let(:number_of_users) { 600 }
      let(:country) { 'United States of America' }

      let(:group) { Resource::Group.fabricate_via_api! }

      before do
        group.add_member(user)
        Flow::Login.sign_in(as: user)
      end

      after do
        user.remove_via_api!
        group.remove_via_api!
      end

      describe 'starts a free trial' do
        context 'when on about page' do
          before do
            Runtime::Browser.visit(:about, Chemlab::Vendor::GitlabHandbook::Page::About)

            Chemlab::Vendor::GitlabHandbook::Page::About.perform(&:get_free_trial)

            Page::Trials::New.perform(&:visit)
          end

          it 'registers for a new trial', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1851' do
            Page::Trials::New.perform do |new|
              # setter
              new.company_name = company_name
              new.number_of_employees = number_of_employees
              new.telephone_number = telephone_number
              new.number_of_users = number_of_users
              new.country = country

              new.continue
            end

            Page::Trials::Select.perform do |select|
              select.new_group_name = group.name
              select.trial_individual
              select.start_your_free_trial
            end

            Page::Alert::FreeTrial.perform do |free_trial_alert|
              expect(free_trial_alert.trial_activated_message).to have_text('Congratulations, your free trial is activated')
            end
          end
        end
      end
    end
  end
end
