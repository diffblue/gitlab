# frozen_string_literal: true

module Geo
  class AttachmentLegacyRegistryFinder < FileRegistryFinder
    def registry_class
      Geo::UploadRegistry
    end
  end
end
