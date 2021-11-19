# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Geo::JobArtifactRegistriesResolver do
  it_behaves_like 'a Geo registries resolver', :geo_job_artifact_registry
end
