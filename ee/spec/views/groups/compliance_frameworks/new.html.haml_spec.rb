# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/compliance_frameworks/new.html.haml' do
  let_it_be(:group) { build(:group) }
  let_it_be(:user) { build(:user) }

  before do
    assign(:group, group)

    allow(view).to receive(:current_user).and_return(user)
    allow(user).to receive(:can_admin_all_resources?).and_return(false)
    allow(user).to receive(:can?).with(:admin_compliance_pipeline_configuration, group).and_return(true)
  end

  it 'shows the compliance frameworks form', :aggregate_failures do
    render

    expect(rendered).to have_content('New compliance framework')
    expect(rendered).to have_css('#js-compliance-frameworks-form')
  end
end
