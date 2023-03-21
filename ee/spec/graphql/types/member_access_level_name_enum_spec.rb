# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MemberAccessLevelNameEnum, feature_category: :security_policy_management do
  specify { expect(described_class.graphql_name).to eq('MemberAccessLevelName') }

  it 'exposes the expected fields' do
    expect(described_class.values.keys).to include(*%w[GUEST REPORTER DEVELOPER MAINTAINER OWNER])
  end
end
