# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/group', feature_category: :groups_and_projects do
  let(:user) { build_stubbed(:user) }
  let_it_be(:group) { create(:group) }

  before do
    assign(:group, group)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
  end

  context 'when free plan limit alert is present' do
    it 'renders the alert partial' do
      render

      expect(rendered).to render_template('shared/_free_user_cap_alert')
    end
  end
end
