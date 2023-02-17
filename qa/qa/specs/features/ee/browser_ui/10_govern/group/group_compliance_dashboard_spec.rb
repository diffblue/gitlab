# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :skip_live_env, product_group: :compliance do
    describe 'compliance dashboard' do
      let!(:approver1) do
        Resource::User.fabricate_via_api! do |usr|
          usr.name = "user1-compliance-dashboard-#{SecureRandom.hex(8)}"
        end
      end

      let!(:approver1_api_client) { Runtime::API::Client.new(:gitlab, user: approver1) }
      let(:author_api_client) { Runtime::API::Client.new(:gitlab) }

      let(:number_of_approvals_violation) { "Less than 2 approvers" }
      let(:author_approval_violation) { "Approved by author" }
      let(:committer_approval_violation) { "Approved by committer" }

      let(:group) do
        Resource::Group.fabricate_via_api! do |grp|
          grp.path = "test-group-compliance-#{SecureRandom.hex(8)}"
        end
      end

      let!(:project) do
        Resource::Project.fabricate_via_api! do |proj|
          proj.name = 'project-compliance-dashboard'
          proj.group = group
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = project
          mr.title = "compliance-dashboard-mr-#{SecureRandom.hex(6)}"
          mr.source_branch = "test-compliance-report-branch-#{SecureRandom.hex(8)}"
        end
      end

      context 'with separation of duties in an MR' do
        before do
          project.update_approval_configuration(merge_requests_author_approval: true)
          project.add_member(approver1, Resource::Members::AccessLevel::MAINTAINER)
        end

        context 'when there is only one approval from a user other than the author' do
          before do
            merge_request.api_client = approver1_api_client
            merge_request.approve
            merge_request.merge_via_api!
            Flow::Login.sign_in
            merge_request.visit!
          end

          it 'shows only "less than two approvers" violation',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390949' do
            group.visit!
            Page::Group::Menu.perform(&:click_compliance_report_link)
            QA::EE::Page::Group::Compliance::Show.perform do |compliance_report|
              expect(compliance_report).to have_violation("Less than 2 approvers", merge_request.title)
              expect(compliance_report).not_to have_violation(author_approval_violation, merge_request.title)
              expect(compliance_report).not_to have_violation(committer_approval_violation, merge_request.title)
            end
          end
        end

        context 'when there are two approvals but one of the approvers is the author' do
          before do
            merge_request.approve
            merge_request.api_client = approver1_api_client
            merge_request.approve
            merge_request.api_client = author_api_client
            merge_request.merge_via_api!
            Flow::Login.sign_in
            merge_request.visit!
          end

          it 'shows only "author approved merge request" and "approved by committer" violations',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/390948' do
            group.visit!
            Page::Group::Menu.perform(&:click_compliance_report_link)
            QA::EE::Page::Group::Compliance::Show.perform do |compliance_report|
              expect(compliance_report).not_to have_violation(number_of_approvals_violation, merge_request.title)
              expect(compliance_report).to have_violation(author_approval_violation, merge_request.title)
              expect(compliance_report).to have_violation(committer_approval_violation, merge_request.title)
            end
          end
        end
      end
    end
  end
end
