# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PipelineArtifactRegistryFinder, feature_category: :geo_replication do
  it_behaves_like 'a framework registry finder', :geo_pipeline_artifact_registry
end
