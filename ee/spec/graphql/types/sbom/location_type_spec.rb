# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Sbom::LocationType, feature_category: :dependency_management do
  let(:fields) { %i[blob_path path] }

  it { expect(described_class).to have_graphql_fields(fields) }
end
