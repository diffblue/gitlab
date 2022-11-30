# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastScanMethodType'] do
  it 'exposes all alert field names' do
    expect(described_class.values.keys).to match_array(%w(WEBSITE OPENAPI HAR POSTMAN_COLLECTION GRAPHQL))
  end
end
