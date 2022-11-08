# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :product_planning do
    describe 'Epics roadmap' do
      include Support::Dates

      let(:epic) do
        EE::Resource::Epic.fabricate_via_api! do |epic|
          epic.title = 'Epic created via API to test roadmap'
          epic.start_date_is_fixed = true
          epic.start_date_fixed = current_date_yyyy_mm_dd
          epic.due_date_is_fixed = true
          epic.due_date_fixed = next_month_yyyy_mm_dd
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'presents epic on roadmap', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347992' do
        page.visit("#{epic.group.web_url}/-/roadmap")

        EE::Page::Group::Roadmap.perform do |roadmap|
          expect(roadmap.epic_present?(epic)).to be_truthy
        end
      end
    end
  end
end
