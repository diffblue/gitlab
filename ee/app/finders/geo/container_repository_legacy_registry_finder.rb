# frozen_string_literal: true

module Geo
  class ContainerRepositoryLegacyRegistryFinder < RegistryFinder
    def registry_class
      Geo::ContainerRepositoryRegistry
    end
  end
end
