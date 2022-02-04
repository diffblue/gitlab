# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'filtered search bar' do |tokens|
  minimum_values_for_token = {
    # Count must be at least 2 as current user are available by default
    "Author" => 2,

    # Count must be at least 3 as `None` & `Any` are available by default
    "Label" => 3,

    # Count must be at least 3 as `Upcoming` & `Started` are available by default
    "Milestone" => 3,

    # Count must be at least 1
    "Epic" => 1,

    # Count must be at least 3 as `None` & `Any` are available by default
    "My-Reaction" => 3
  }

  def select_token(token_name)
    page.find('input.gl-filtered-search-term-input').click
    click_link token_name
    page.first('.gl-filtered-search-suggestion').click
  end

  tokens.each do |token|
    it "renders values for token '#{token}' correctly" do
      page.within('.vue-filtered-search-bar-container .gl-search-box-by-click') do
        select_token(token)

        wait_for_requests

        expect(page.find('.gl-filtered-search-suggestion-list')).to have_selector('li.gl-filtered-search-suggestion', minimum: minimum_values_for_token[token])
      end
    end
  end
end
