# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :requires_admin, product_group: :optimize do
    shared_examples "value stream analytics" do
      it "shows vsa dashboard" do
        EE::Page::Group::ValueStreamAnalytics.perform do |vsa_page|
          expect(vsa_page).to have_stages(stage_names)
          expect(vsa_page).to have_text("'#{vsa_name}' is collecting the data. This can take a few minutes.")
        end
      end
    end

    describe 'Value stream analytics' do
      let(:vsa_name) { "test-vsa" }
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:user_api_client) { Runtime::API::Client.new(user: user) }

      let!(:user) do
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

      let(:project) do
        Resource::Project.fabricate_via_api! do |resource|
          resource.api_client = user_api_client
          resource.group = group
        end
      end

      before do
        group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        Flow::Login.sign_in(as: user)
        project.visit!
        Page::Project::Menu.perform(&:go_to_value_stream_analytics)
      end

      context "with default template", testcase: "https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/414821" do
        let(:stage_names) { %w[Issue Plan Code Test Review Staging] }

        before do
          EE::Page::Group::ValueStreamAnalytics.perform do |vsa_page|
            vsa_page.create_new_value_stream_from_default_template(vsa_name)
          end
        end

        it_behaves_like "value stream analytics"
      end

      context "with custom template", testcase: "https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415068" do
        let(:stage_names) { stages.pluck(:name) }

        let(:stages) do
          [
            {
              name: "issues closed",
              start_event: "Issue created",
              end_event: "Issue closed"
            },
            {
              name: "mrs merged",
              start_event: "Merge request created",
              end_event: "Merge request merged"
            }
          ]
        end

        before do
          EE::Page::Group::ValueStreamAnalytics.perform do |vsa_page|
            vsa_page.create_new_custom_value_stream(vsa_name, stages)
          end
        end

        it_behaves_like "value stream analytics"
      end
    end
  end
end
