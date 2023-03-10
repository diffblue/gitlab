# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PipelineArtifactReplicator, feature_category: :geo_replication do
  let(:model_record) { build(:ci_pipeline_artifact, :with_coverage_report) }

  include_examples 'a blob replicator'
  it_behaves_like 'a verifiable replicator'
end
