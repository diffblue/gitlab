# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Search::Migration, :elastic, feature_category: :global_search do
  let(:migration) { Elastic::DataMigrationService.migrations.last }

  subject(:api_response) { described_class.new(migration).as_json }

  it 'exposes correct attributes' do
    expect(api_response.keys).to contain_exactly(
      :version,
      :name,
      :started_at,
      :completed_at,
      :completed,
      :obsolete,
      :migration_state
    )
  end

  it 'reads completed from the index' do
    allow(migration).to receive(:completed?).and_return(false)

    expect(api_response[:completed]).to eq(true)
  end
end
