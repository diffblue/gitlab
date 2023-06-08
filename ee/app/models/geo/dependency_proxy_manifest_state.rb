# frozen_string_literal: true

module Geo
  class DependencyProxyManifestState < ApplicationRecord
    include ::Geo::VerificationStateDefinition

    self.primary_key = :dependency_proxy_manifest_id

    belongs_to :dependency_proxy_manifest,
      inverse_of: :dependency_proxy_manifest_state,
      class_name: 'DependencyProxy::Manifest'

    validates :verification_state, :dependency_proxy_manifest, presence: true
  end
end
