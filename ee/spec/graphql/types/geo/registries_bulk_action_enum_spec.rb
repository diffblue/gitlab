# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['GeoRegistriesBulkAction'], feature_category: :geo_replication do
  it { expect(described_class.graphql_name).to eq('GeoRegistriesBulkAction') }

  it 'exposes the correct registry actions' do
    expect(described_class.values.keys).to contain_exactly(*%w[REVERIFY_ALL RESYNC_ALL])
  end
end
