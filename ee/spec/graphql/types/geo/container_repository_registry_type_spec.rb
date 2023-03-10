# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryRegistry'], feature_category: :geo_replication do
  it_behaves_like 'a Geo registry type'

  it 'has the expected fields (other than those included in RegistryType)' do
    expected_fields = %i[container_repository_id]

    expect(described_class).to have_graphql_fields(*expected_fields).at_least
  end
end
