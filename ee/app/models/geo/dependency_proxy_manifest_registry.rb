# frozen_string_literal: true

module Geo
  class DependencyProxyManifestRegistry < Geo::BaseRegistry
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry

    MODEL_CLASS = ::DependencyProxy::Manifest
    MODEL_FOREIGN_KEY = :dependency_proxy_manifest_id

    belongs_to :dependency_proxy_manifest, class_name: 'DependencyProxy::Manifest'
  end
end
