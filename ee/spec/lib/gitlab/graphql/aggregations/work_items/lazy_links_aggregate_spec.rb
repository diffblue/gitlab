# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Aggregations::WorkItems::LazyLinksAggregate, feature_category: :portfolio_management do
  it_behaves_like 'issuable lazy links aggregate' do
    let(:issuable_id) { 37 }

    let(:issuable_link_class) { ::WorkItems::RelatedWorkItemLink }

    let(:fake_blocked_data) do
      [
        { blocked_issue_id: 1745, count: 1.0 },
        nil # nil for unblocked issuables
      ]
    end

    let(:fake_blocking_data) do
      [
        { blocking_issue_id: 1745, count: 1.0 },
        nil # nil for unblocked issuables
      ]
    end
  end
end
