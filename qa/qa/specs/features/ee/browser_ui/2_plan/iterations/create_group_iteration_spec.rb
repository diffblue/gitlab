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

      let(:group) do
        QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "group-to-test-iterations-cadences-#{SecureRandom.hex(8)}"
        end
      end

      before do
        Runtime::Feature.enable(:iteration_cadences, group: group)

        Flow::Login.sign_in
      end

      it 'creates a group iteration', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1623' do
        # TODO: Remove this retry when the `Runtime::Feature.enable` method call is removed
        Support::Retrier.retry_on_exception(max_attempts: 5) do
          group.visit!
          QA::Page::Group::Menu.perform(&:go_to_group_iterations)
          QA::EE::Page::Group::Iteration::Cadence::Index.perform do |cadence|
            cadence.find_element(:create_new_cadence_button)
          end
        end

        EE::Resource::GroupIteration.fabricate_via_browser_ui! do |iteration|
          iteration.title = title
          iteration.description = description
          iteration.due_date = due_date
          iteration.start_date = start_date
          iteration.group = group
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
