# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLink, feature_category: :portfolio_management do
  it_behaves_like 'includes LinkableItem concern (EE)' do
    let_it_be(:item_factory) { :issue }
    let_it_be(:link_factory) { :issue_link }
    let_it_be(:link_class) { described_class }
  end
end
