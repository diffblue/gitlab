# frozen_string_literal: true

module Sbom
  class DependencyLocationEntity < Grape::Entity
    include RequestAwareEntity

    class LocationEntity < Grape::Entity
      expose :blob_path, :path
    end

    class ProjectEntity < Grape::Entity
      expose :name
    end

    expose :location, using: LocationEntity
    expose :project, using: ProjectEntity
  end
end
