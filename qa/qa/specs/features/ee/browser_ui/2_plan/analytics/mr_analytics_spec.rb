# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    describe 'Merge Request Analytics', :requires_admin, product_group: :optimize do
      let(:label) { "mr-label" }
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:user_api_client) { Runtime::API::Client.new(user: user) }

      let(:user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = admin_api_client
        end
      end

      let(:group) { create(:group, path: "mr-analytics-#{SecureRandom.hex(8)}") }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'mr_analytics'
          project.group = group
          project.api_client = user_api_client
        end
      end

      let(:mr_1) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.title = "First merge request"
          mr.labels = [label]
          mr.project = project
          mr.api_client = user_api_client
        end
      end

      let(:mr_2) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.title = "Second merge request"
          mr.project = project
          mr.api_client = user_api_client
        end
      end

      before do
        group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        Resource::ProjectLabel.fabricate_via_api! do |resource|
          resource.project = project
          resource.title = label
          resource.api_client = user_api_client
        end

        mr_2.add_comment(body: "This is mr comment")
        mr_1.merge_via_api!
        mr_2.merge_via_api!

        Flow::Login.sign_in(as: user)
        project.visit!
        Page::Project::Menu.perform(&:go_to_merge_request_analytics)
      end

      it(
        "shows merge request analytics chart and stats",
        testcase: "https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/416723"
      ) do
        EE::Page::Project::MergeRequestAnalytics.perform do |mr_analytics_page|
          expect(mr_analytics_page.throughput_chart).to be_visible
          # chart elements will be loaded even when no data is fetched,
          # so explicit check for missing no data warning is required
          expect(mr_analytics_page).not_to(
            have_content("There is no chart data available"),
            "Expected chart data to be available"
          )

          aggregate_failures do
            expect(mr_analytics_page.mean_time_to_merge).to eq("0 days")
            expect(mr_analytics_page.merged_mrs(expected_count: 2)).to match_array([
              {
                title: mr_1.title,
                label_count: 1,
                comment_count: 0
              },
              {
                title: mr_2.title,
                label_count: 0,
                comment_count: 1
              }
            ])
          end
        end
      end
    end
  end
end
