# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Aggregations::Issues::LazyLinksAggregate do
  it_behaves_like 'issuable lazy links aggregate' do
    let(:issuable_id) { 37 }

    let(:issuable_link_class) { IssueLink }

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
