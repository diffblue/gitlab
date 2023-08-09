# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::JobArtifactReplicator, feature_category: :geo_replication do
  let(:model_record) { create(:ci_job_artifact, :with_file) }

  include_examples 'a blob replicator'
end
