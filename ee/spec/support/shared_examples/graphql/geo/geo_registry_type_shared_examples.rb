# frozen_string_literal: true

RSpec.shared_examples_for 'a Geo registry type' do |registry_factory_name|
  it { expect(described_class).to require_graphql_authorizations(:read_geo_registry) }

  it 'has the expected fields' do
    expected_fields = %i[
      id state retry_count last_sync_failure retry_at last_synced_at verified_at
      verification_retry_at created_at verification_state verification_started_at
      verification_retry_count verification_checksum verification_failure
    ]

    expect(described_class).to have_graphql_fields(*expected_fields).at_least
  end
end
