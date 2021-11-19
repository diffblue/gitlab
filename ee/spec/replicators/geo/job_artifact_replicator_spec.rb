# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::JobArtifactReplicator do
  let(:model_record) { create(:ci_job_artifact, :with_file) }

  include_examples 'a blob replicator'
  include_examples 'a verifiable replicator'
end
