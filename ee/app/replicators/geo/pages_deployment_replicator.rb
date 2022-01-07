# frozen_string_literal: true

module Geo
  class PagesDeploymentReplicator < Gitlab::Geo::Replicator
    include ::Geo::BlobReplicatorStrategy
    extend ::Gitlab::Utils::Override

    def self.model
      ::PagesDeployment
    end

    def carrierwave_uploader
      model_record.file
    end

    override :verification_feature_flag_enabled?
    def self.verification_feature_flag_enabled?
      true
    end
  end
end
