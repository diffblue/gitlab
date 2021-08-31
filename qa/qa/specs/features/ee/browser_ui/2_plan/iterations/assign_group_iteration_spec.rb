# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable do
    describe 'Assign Iterations' do
      let!(:iteration) { EE::Resource::GroupIteration.fabricate_via_api! }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = iteration.group
          project.name = "project-to-test-iterations-#{SecureRandom.hex(8)}"
        end
      end

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
          issue.title = "issue-to-test-iterations-#{SecureRandom.hex(8)}"
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'assigns a group iteration to an existing issue', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1624' do
        issue.visit!

        Page::Project::Issue::Show.perform do |issue|
          issue.assign_iteration(iteration)

          expect(issue).to have_iteration(iteration.title)
        end
      end
    end
  end
end
