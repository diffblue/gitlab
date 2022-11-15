# frozen_string_literal: true

module Geo
  class DependencyProxyBlobRegistry < Geo::BaseRegistry
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry

    MODEL_CLASS = ::DependencyProxy::Blob
    MODEL_FOREIGN_KEY = :dependency_proxy_blob_id

    belongs_to :dependency_proxy_blob, class_name: 'DependencyProxy::Blob'
  end
end
