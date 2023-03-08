# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Test case shortcuts", :js, feature_category: :quality_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:label_bug) { create(:label, project: project, title: 'bug') }
  let_it_be(:test_case) { create(:quality_test_case, project: project, author: user, labels: [label_bug]) }

  before do
    project.add_developer(user)
    stub_licensed_features(quality_management: true)
    sign_in(user)

    visit project_quality_test_case_path(project, test_case)
    wait_for_all_requests
  end

  describe 'pressing "l"' do
    it "opens labels dropdown for editing" do
      find('body').native.send_key('l')

      expect(find('.js-labels-block')).to have_selector('[data-testid="labels-select-dropdown-contents"]')
    end
  end
end
