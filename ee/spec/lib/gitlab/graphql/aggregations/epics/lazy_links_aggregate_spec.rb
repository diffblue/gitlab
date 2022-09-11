# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Aggregations::Epics::LazyLinksAggregate do
  it_behaves_like 'issuable lazy links aggregate' do
    let(:issuable_id) { 40 }

    let(:issuable_link_class) { Epic::RelatedEpicLink }

    let(:fake_blocked_data) do
      [
        { blocked_epic_id: 135, count: 1.0 },
        nil # nil for unblocked issuables
      ]
    end

    let(:fake_blocking_data) do
      [
        { blocking_epic_id: 135, count: 1.0 },
        nil # nil for unblocked issuables
      ]
    end
  end
end
