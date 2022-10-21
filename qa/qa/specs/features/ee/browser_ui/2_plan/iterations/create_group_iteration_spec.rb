# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', feature_flag: { name: 'iteration_cadences', scope: :group } do
    describe 'Group Iterations', product_group: :project_management do
      include Support::Dates

      let(:title) { "Group iteration cadence created via GUI #{SecureRandom.hex(8)}" }
      let(:start_date) { current_date_yyyy_mm_dd }
      let(:due_date) { thirteen_days_from_now_yyyy_mm_dd }
      let(:description) { "This is a group test iteration cadence." }
      let(:iteration_period) { "#{format_date(start_date)} - #{format_date(due_date)}" }

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

      it 'creates a group iteration automatically through an iteration cadence', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347943' do
        EE::Resource::GroupCadence.fabricate_via_browser_ui! do |cadence|
          cadence.group = iteration_group
          cadence.title = title
          cadence.description = description
          cadence.start_date = start_date
          cadence.duration = 2
          cadence.upcoming_iterations = 2
        end

        EE::Page::Group::Iteration::Cadence::Index.perform do |cadence|
          cadence.retry_on_exception(reload: cadence) do
            cadence.open_iteration(title, iteration_period)
          end
        end

        EE::Page::Group::Iteration::Show.perform do |iteration|
          aggregate_failures "iteration created successfully" do
            expect(iteration).to have_content(iteration_period)
            expect(iteration).to have_burndown_chart
            expect(iteration).to have_burnup_chart
          end
        end
      end
    end
  end
end
