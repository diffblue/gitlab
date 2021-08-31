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

    # The feature flag follows the format `geo_#{replicable_name}_replication`,
    # so here it would be `geo_pages_deployment_replication`
    def self.replication_enabled_by_default?
      false
    end

    override :verification_feature_flag_enabled?
    def self.verification_feature_flag_enabled?
      false
    end
  end
end
