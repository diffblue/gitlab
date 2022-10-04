# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BoardIssueInput'] do
  it 'has specific fields' do
    allowed_args = %w(epicId epicWildcardId iterationTitle iterationWildcardId weight healthStatusFilter)

    expect(described_class.arguments.keys).to include(*allowed_args)
  end
end
