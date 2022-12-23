# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OKR', :js, feature_category: :product_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:type_objective) { WorkItems::Type.default_by_type(:objective) }
  let_it_be(:type_key_result) { WorkItems::Type.default_by_type(:key_result) }
  let_it_be(:objective) { create(:work_item, work_item_type: type_objective, project: project) }
  let_it_be(:key_result) { create(:work_item, work_item_type: type_key_result, project: project) }

  before do
    group.add_developer(user)

    sign_in(user)

    stub_licensed_features(okrs: true)

    stub_feature_flags(work_items: true)
    stub_feature_flags(okrs_mvc: true)
  end

  context 'for objective' do
    before do
      visit project_work_items_path(project, work_items_path: objective.id)
    end

    it 'has progress widget' do
      expect(page).to have_selector('[data-testid="work-item-progress"]')
    end

    context 'in heirarchy' do
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

          click_button 'Add'
          click_button 'New key result'

          expect(find('[data-testid="add-tree-form"]')).to have_button('Create key result', disabled: true)

          click_button 'Add'
          click_button 'Existing key result'

          expect(find('[data-testid="add-tree-form"]')).to have_button('Add key result', disabled: true)

          click_button 'Cancel'

          expect(page).not_to have_selector('[data-testid="add-tree-form"]')
        end
      end
    end
  end

  context 'for keyresult' do
    before do
      visit project_work_items_path(project, work_items_path: key_result.id)
    end

    it 'has progress widget' do
      expect(page).to have_selector('[data-testid="work-item-progress"]')
    end
  end

  context 'for progress input widget' do
    before do
      visit project_work_items_path(project, work_items_path: objective.id)
    end

    it 'prevents typing values outside min and max range', :aggregate_failures do
      page_body = page.find('body')
      page.within('[data-testid="work-item-progress"]') do
        progress_input = find('input#progress-widget-input')
        progress_input.native.send_keys('101')
        page_body.click

        expect(progress_input.value).to eq('')

        # Clear input
        progress_input.set('')
        progress_input.native.send_keys('-')
        page_body.click

        expect(progress_input.value).to eq('')
      end
    end

    it 'prevent typing special characters `+`, `-`, and `e`', :aggregate_failures do
      page_body = page.find('body')
      page.within('[data-testid="work-item-progress"]') do
        progress_input = find('input#progress-widget-input')

        progress_input.native.send_keys('+')
        page_body.click
        expect(progress_input.value).to eq('')

        progress_input.native.send_keys('-')
        page_body.click
        expect(progress_input.value).to eq('')

        progress_input.native.send_keys('e')
        page_body.click
        expect(progress_input.value).to eq('')
      end
    end
  end
end
