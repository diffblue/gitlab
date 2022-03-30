# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/group_members/index' do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    allow(view).to receive(:group_members_app_data).and_return({})
    allow(view).to receive(:current_user).and_return(user)
    assign(:group, group)
  end

  context 'when free plan limit alert is present' do
    it 'renders the alert partial' do
      render

      expect(rendered).to render_template('shared/_user_over_limit_free_plan_alert')
    end
  end
end
