# frozen_string_literal: true

module Sbom
  class SbomLicenseEntity < Grape::Entity
    include Gitlab::Utils::StrongMemoize

    expose :license do
      expose :spdx_identifier, as: :id, override: true, unless: proc { |license| unknown?(license) }
      expose :name, override: true, if: proc { |license| unknown?(license) }
      expose :url, override: true, unless: proc { |license| unknown?(license) } do |license|
        ::Gitlab::Ci::Reports::LicenseScanning::License.spdx_url(license[:spdx_identifier])
      end
    end

    private

    def unknown?(license)
      strong_memoize_with(:unknown, license) do
        Gitlab::Ci::Reports::LicenseScanning::License.unknown?(license)
      end
    end
  end

  class SbomComponentsEntity < Grape::Entity
    expose :name
    expose :version
    expose :purl
    expose :type
    expose :licenses do |component|
      component[:licenses].map do |license|
        SbomLicenseEntity.represent(license)
      end
    end
  end

  class SbomMetadataEntity < Grape::Entity
    expose :timestamp, expose_nil: false
    expose :authors
    expose :properties
    expose :tools
  end

  class SbomAttributes < Grape::Entity
    expose :bom_format, as: :bomFormat
    expose :spec_version, as: :specVersion
    expose :serial_number, as: :serialNumber
    expose :version
  end

  class SbomEntity < Grape::Entity
    expose :sbom_attributes, merge: true, using: SbomAttributes
    expose :metadata, using: SbomMetadataEntity
    expose :components, using: SbomComponentsEntity
  end
end
