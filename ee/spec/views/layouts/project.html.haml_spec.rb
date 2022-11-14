# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/project' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before do
    assign(:project, project)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
  end

  context 'when free plan limit alert is present' do
    it 'renders the alert partial' do
      render

      expect(rendered).to render_template('projects/_free_user_cap_alert')
    end
  end
end
