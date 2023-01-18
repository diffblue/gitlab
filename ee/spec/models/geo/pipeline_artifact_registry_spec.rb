# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PipelineArtifactRegistry, :geo, type: :model do
  let(:registry) { create(:geo_pipeline_artifact_registry) }

  specify 'factory is valid' do
    expect(registry).to be_valid
  end

  include_examples 'a Geo framework registry'
  include_examples 'a Geo verifiable registry'
  include_examples 'a Geo searchable registry'
end
