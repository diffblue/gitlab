# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :requires_admin, product_group: :optimize do
    describe 'Value stream analytics' do
      let(:vsa_name) { "test-vsa" }
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let(:user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = admin_api_client
        end
      end

      let(:group) do
        Resource::Group.fabricate_via_api! do |resource|
          resource.api_client = admin_api_client
          resource.path = "group-for-vsa-#{SecureRandom.hex(4)}"
        end
      end

      before do
        group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        Flow::Login.sign_in(as: user)
        group.visit!
        Page::Group::Menu.perform(&:go_to_value_stream_analytics)
      end

      it(
        "can create value stream analytics from default template",
        testcase: "https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/414821"
      ) do
        EE::Page::Group::ValueStreamAnalytics.perform do |vsa_page|
          vsa_page.create_new_value_stream_from_default_template(vsa_name)

          expect(vsa_page).to have_element(:vsa_path_navigation)
          expect(vsa_page).to have_text("'#{vsa_name}' is collecting the data. This can take a few minutes.")
        end
      end

      it(
        "can create custom value stream analytics",
        testcase: "https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415068"
      ) do
        EE::Page::Group::ValueStreamAnalytics.perform do |vsa_page|
          vsa_page.create_new_custom_value_stream(vsa_name, [
            {
              name: "issues closed stage",
              start_event: "Issue created",
              end_event: "Issue closed"
            },
            {
              name: "mrs closed stage",
              start_event: "Merge request created",
              end_event: "Merge request closed"
            }
          ])

          expect(vsa_page).to have_element(:vsa_path_navigation)
          expect(vsa_page).to have_text("'#{vsa_name}' is collecting the data. This can take a few minutes.")
        end
      end
    end
  end
end
