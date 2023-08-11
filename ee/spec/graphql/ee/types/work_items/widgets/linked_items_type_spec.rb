# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Types::WorkItems::Widgets::LinkedItemsType, feature_category: :portfolio_management do
  let(:extended_class) { Types::WorkItems::Widgets::LinkedItemsType }

  it 'includes the ee specific fields' do
    expect(extended_class).to have_graphql_fields(
      :blocked, :blocking_count, :blocked_by_count
    ).at_least
  end
end
