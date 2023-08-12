# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :requires_admin, product_group: :optimize do
    describe 'Value stream analytics' do
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:default_stage_names) { %w[Issue Plan Code Test Review Staging] }

      context "without pre-existing dashboard" do
        shared_examples "value stream analytics" do
          it "shows vsa dashboard" do
            EE::Page::Group::ValueStreamAnalytics.perform do |vsa_page|
              expect(vsa_page).to have_stages(stage_names)
              expect(vsa_page).to have_text("'#{vsa_name}' is collecting the data. This can take a few minutes.")
            end
          end
        end

        let(:vsa_name) { "test-vsa" }

        let!(:user) do
          Resource::User.fabricate_via_api! do |resource|
            resource.api_client = admin_api_client
          end
        end

        let(:group) { create(:group, api_client: admin_api_client, path: "group-for-vsa-#{SecureRandom.hex(4)}") }

        let(:project) do
          Resource::Project.fabricate_via_api! do |resource|
            resource.api_client = admin_api_client
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
          let(:stage_names) { default_stage_names }

          before do
            EE::Page::Project::ValueStreamAnalytics.perform do |vsa_page|
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
            EE::Page::Project::ValueStreamAnalytics.perform do |vsa_page|
              vsa_page.create_new_custom_value_stream(vsa_name, stages)
            end
          end

          it_behaves_like "value stream analytics"
        end
      end

      context("with pre-existing dashboard",
        testcase: "https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/417268",
        only: { subdomain: :staging }
      ) do
        let!(:user) { Runtime::User.admin }

        let!(:group) do
          Resource::Sandbox.init do |resource|
            resource.api_client = admin_api_client
            resource.path = "optimize-vsa-test"
          end.reload!
        end

        let!(:project) do
          Resource::Project.init do |resource|
            resource.add_name_uuid = false
            resource.api_client = admin_api_client
            resource.group = group
            resource.path = "optimize-sandbox"
            resource.name = "optimize-sandbox"
          end.reload!
        end

        before do
          Flow::Login.sign_in(as: user)
          project.visit!
          Page::Project::Menu.perform(&:go_to_value_stream_analytics)
        end

        it "displays VSA page with correct lifecycle metrics and overview chart" do
          EE::Page::Project::ValueStreamAnalytics.perform do |vsa_page|
            aggregate_failures do
              expect(vsa_page).to have_stages(default_stage_names)
              expect(vsa_page.lifecycle_metrics).to be_visible
              expect(vsa_page.overview_chart).to be_visible
            end

            vsa_page.select_date_range(from: "2023-06-10", to: "2023-07-10")
            aggregate_failures "Checking lifecycle metrics" do
              expect(vsa_page.lifecycle_metric(:lead_time)).to eq("852.7 days")
              expect(vsa_page.lifecycle_metric(:cycle_time)).to eq("1.4 days")
              expect(vsa_page.lifecycle_metric(:issues)).to eq(33)
              expect(vsa_page.lifecycle_metric(:commits)).to eq(86)
              expect(vsa_page.lifecycle_metric(:deploys)).to eq(4)
            end
          end
        end
      end
    end
  end
end
