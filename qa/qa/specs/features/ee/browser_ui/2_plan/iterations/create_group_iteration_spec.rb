# frozen_string_literal: true

module QA
  # TODO: Remove :requires_admin when the `Runtime::Feature.enable` method call is removed
  RSpec.describe 'Plan', :requires_admin do
    describe 'Group Iterations' do
      include Support::Dates

      let(:title) { "Group iteration created via GUI #{SecureRandom.hex(8)}" }
      let(:start_date) { current_date_yyyy_mm_dd }
      let(:due_date) { next_month_yyyy_mm_dd }
      let(:description) { "This is a group test iteration." }

      let!(:iteration_group) do
        QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "group-to-test-creating-iteration-cadences-#{SecureRandom.hex(8)}"
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
      end

      it 'creates a group iteration', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347943' do
        EE::Resource::GroupIteration.fabricate_via_browser_ui! do |iteration|
          iteration.title = title
          iteration.description = description
          iteration.due_date = due_date
          iteration.start_date = start_date
          iteration.group = iteration_group
        end

        EE::Page::Group::Iteration::Show.perform do |iteration|
          aggregate_failures "iteration created successfully" do
            expect(iteration).to have_content(title)
            expect(iteration).to have_content(description)
            expect(iteration).to have_content(format_date(start_date))
            expect(iteration).to have_content(format_date(due_date))
          end
        end
      end
    end
  end
end
