# frozen_string_literal: true

module Sbom
  class DependencyLocationListEntity < Grape::Entity
    present_collection true, :locations

    expose :locations, using: Sbom::DependencyLocationEntity
  end
end
