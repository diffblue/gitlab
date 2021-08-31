# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable do
    describe 'Group Iterations' do
      include Support::Dates

      let(:title) { "Group iteration created via GUI #{SecureRandom.hex(8)}" }
      let(:start_date) { current_date_yyyy_mm_dd }
      let(:due_date) { next_month_yyyy_mm_dd }
      let(:description) { "This is a group test iteration." }

      before do
        Flow::Login.sign_in
      end

      it 'creates a group iteration', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1623', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/334252', type: :stale } do
        EE::Resource::GroupIteration.fabricate_via_browser_ui! do |iteration|
          iteration.title = title
          iteration.description = description
          iteration.due_date = due_date
          iteration.start_date = start_date
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
