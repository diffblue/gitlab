# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GeoRegistryAction'], feature_category: :geo_replication do
  it { expect(described_class.graphql_name).to eq('GeoRegistryAction') }

  it 'exposes the correct registry actions' do
    expect(described_class.values.keys).to contain_exactly(*%w[REVERIFY RESYNC])
  end
end
