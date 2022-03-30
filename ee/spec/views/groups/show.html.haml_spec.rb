# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/show' do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:group_path).and_return('_group_path_')
    allow(view).to receive(:group_shared_path).and_return('_group_shared_path_')
    allow(view).to receive(:group_archived_path).and_return('_group_archived_path_')
    assign(:group, group)
  end

  context 'when free plan limit alert is present' do
    it 'renders the alert partial' do
      render

      expect(rendered).to render_template('shared/_user_over_limit_free_plan_alert')
    end
  end
end
