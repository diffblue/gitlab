# frozen_string_literal: true

module Geo
  class JobArtifactLegacyRegistryFinder < FileRegistryFinder
    def registry_class
      Geo::JobArtifactRegistry
    end
  end
end
