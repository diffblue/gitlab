# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OKR hierarchy', :js, feature_category: :product_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:type_objective) { WorkItems::Type.default_by_type(:objective) }
  let_it_be(:objective) { create(:work_item, work_item_type: type_objective, project: project) }

  context 'for signed in user' do
    before do
      group.add_developer(user)

      sign_in(user)

      stub_licensed_features(okrs: true)

      stub_feature_flags(work_items: true)
      stub_feature_flags(okrs_mvc: true)
      stub_feature_flags(hierarchy_db_restrictions: true)

      visit project_work_items_path(project, work_items_path: objective.id)
    end

    it 'shows no children', :aggregate_failures do
      page.within('[data-testid="work-item-tree"]') do
        expect(page).to have_content('Child objectives and key results')
        expect(page).to have_content('No objectives or key results are currently assigned.')
      end
    end

    it 'toggles widget body', :aggregate_failures do
      page.within('[data-testid="work-item-tree"]') do
        expect(page).to have_selector('[data-testid="tree-body"]')

        click_button 'Collapse'

        expect(page).not_to have_selector('[data-testid="tree-body"]')

        click_button 'Expand'

        expect(page).to have_selector('[data-testid="tree-body"]')
      end
    end

    it 'toggles forms', :aggregate_failures do
      page.within('[data-testid="work-item-tree"]') do
        expect(page).not_to have_selector('[data-testid="add-tree-form"]')

        click_button 'Add'
        click_button 'New objective'

        expect(page).to have_selector('[data-testid="add-tree-form"]')
        expect(find('[data-testid="add-tree-form"]')).to have_button('Create objective', disabled: true)

        click_button 'Add'
        click_button 'Existing objective'

        expect(find('[data-testid="add-tree-form"]')).to have_button('Add objective', disabled: true)

        # TODO: Uncomment once following two issues addressed
        # https://gitlab.com/gitlab-org/gitlab/-/issues/381833
        # https://gitlab.com/gitlab-org/gitlab/-/issues/385084
        # click_button 'Add'
        # click_button 'New key result'

        # expect(find('[data-testid="add-tree-form"]')).to have_button('Create key result', disabled: true)

        # click_button 'Add'
        # click_button 'Existing key result'

        # expect(find('[data-testid="add-tree-form"]')).to have_button('Add key result', disabled: true)

        click_button 'Cancel'

        expect(page).not_to have_selector('[data-testid="add-tree-form"]')
      end
    end
  end
end
