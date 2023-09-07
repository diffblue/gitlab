# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Sbom::LicenseType, feature_category: :dependency_management do
  let(:fields) { %i[name url] }

  it { expect(described_class).to have_graphql_fields(fields) }
end
