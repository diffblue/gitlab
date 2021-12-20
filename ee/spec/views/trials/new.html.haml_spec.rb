# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'trials/new.html.haml' do
  include ApplicationHelper
  let_it_be(:variant) { :control }
  let_it_be(:user) { build(:user) }

  before do
    allow(view).to receive(:current_user) { user }

    render
  end

  subject { rendered }

  it 'has fields for first, last company name and size', :aggregate_failures do
    is_expected.to have_field('first_name')
    is_expected.to have_field('last_name')
    is_expected.to have_field('company_name')
    sizes = ['Please select', '1 - 99', '100 - 499', '500 - 1,999', '2,000 - 9,999', '10,000 +']
    is_expected.to have_select('company_size', options: sizes, selected: [])
  end
end
