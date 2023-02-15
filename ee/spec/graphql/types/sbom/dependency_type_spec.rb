# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Sbom::DependencyType, feature_category: :dependency_management do
  let(:fields) { %i[id name version packager location] }

  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_dependencies) }
  it { expect(described_class.graphql_name).to eq('Dependency') }
end
