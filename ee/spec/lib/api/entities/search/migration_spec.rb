# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Search::Migration, :elastic, feature_category: :global_search do
  let(:migration) { Elastic::DataMigrationService.migrations.last }

  subject { described_class.new(migration).as_json }

  it 'exposes correct attributes' do
    expect(subject).to include(
      :version,
      :name,
      :started_at,
      :completed_at,
      :completed,
      :obsolete,
      :migration_state
    )
  end
end
