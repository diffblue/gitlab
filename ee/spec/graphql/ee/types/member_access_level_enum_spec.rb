# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MemberAccessLevelEnum, feature_category: :groups_and_projects do
  specify { expect(described_class.graphql_name).to eq('MemberAccessLevel') }

  it 'exposes all the existing EE access level values' do
    expect(described_class.values.keys).to include('MINIMAL_ACCESS')
  end
end
