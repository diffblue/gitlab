# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiCatalogResourceSort'], feature_category: :pipeline_composition do
  it { expect(described_class.graphql_name).to eq('CiCatalogResourceSort') }

  it 'exposes all the existing catalog resource sort orders' do
    expect(described_class.values.keys).to include(*%w[NAME_ASC NAME_DESC])
  end
end
