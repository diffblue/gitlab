# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::JobArtifactRegistriesResolver, feature_category: :geo_replication do
  it_behaves_like 'a Geo registries resolver', :geo_job_artifact_registry
end
