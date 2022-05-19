# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, feature_flag: { name: 'iteration_cadences', scope: :group } do
    describe 'Assign Iterations' do
      include Support::Dates

      let!(:start_date) { current_date_yyyy_mm_dd }
      let!(:due_date) { thirteen_days_from_now_yyyy_mm_dd }
      let(:iteration_period) { "#{format_date(start_date)} - #{format_date(due_date)}" }

      let(:iteration_group) do
        QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "group-to-test-assigning-iterations-#{SecureRandom.hex(8)}"
        end
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = iteration_group
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
        Runtime::Feature.enable(:iteration_cadences, group: iteration_group)
        # TODO: this sleep can be removed when the `Runtime::Feature.enable` method call is removed
        # Wait for the application settings cache to update with iteration_cadences feature flag setting
        # as per this issue https://gitlab.com/gitlab-org/gitlab/-/issues/36663
        # We cannot check the UI for the changes because they are sporadically available at first
        # as described in this issue https://gitlab.com/gitlab-org/quality/testcases/-/issues/113#note_300647725
        sleep(60)

        Flow::Login.sign_in

        EE::Resource::GroupCadence.fabricate_via_api! do |cadence|
          cadence.group = iteration_group
          cadence.start_date = start_date
        end
      end

      it(
        'assigns a group iteration to an existing issue',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347942',
        except: { subdomain: 'pre' }
      ) do
        issue.visit!

        Page::Project::Issue::Show.perform do |issue|
          issue.assign_iteration(iteration_period)

          expect(issue).to have_iteration(iteration_period)

          issue.click_iteration(iteration_period)
        end

        EE::Page::Group::Iteration::Show.perform do |iteration|
          aggregate_failures "iteration created successfully" do
            expect(iteration).to have_content(iteration_period)
            expect(iteration).to have_issue(issue)
          end
        end
      end
    end
  end
end
