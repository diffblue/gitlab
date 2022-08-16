# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/hooks/edit' do
  let(:web_hook) { create(:group_hook) }

  before do
    assign :group, web_hook.group
    assign :hook, web_hook
    assign :web_hook_logs, []
    render
  end

  it 'renders the edit group hook section' do
    expect(rendered).to have_text('Edit Group Hook')
  end

  it 'renders the recent events section' do
    expect(rendered).to have_text('Recent events')
  end
end
