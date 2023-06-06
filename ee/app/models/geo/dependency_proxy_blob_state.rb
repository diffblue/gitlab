# frozen_string_literal: true

module Geo
  class DependencyProxyBlobState < ApplicationRecord
    include ::Geo::VerificationStateDefinition

    self.primary_key = :dependency_proxy_blob_id

    belongs_to :dependency_proxy_blob, inverse_of: :dependency_proxy_blob_state, class_name: 'DependencyProxy::Blob'

    validates :verification_state, :dependency_proxy_blob, presence: true
  end
end
