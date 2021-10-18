# frozen_string_literal: true

module Geo
  class UploadReplicator < Gitlab::Geo::Replicator
    include ::Geo::BlobReplicatorStrategy
    extend ::Gitlab::Utils::Override

    def self.model
      ::Upload
    end

    def carrierwave_uploader
      model_record.retrieve_uploader
    end

    # TODO: This method can be removed as part of
    # https://gitlab.com/gitlab-org/gitlab/-/issues/340617
    override :registry
    def registry
      super.tap do |record|
        # We don't really need this value for SSF, it's only needed to make
        # new registry records valid for legacy code in case of disabling the feature.
        record.file_type ||= model_record.uploader.delete_suffix("Uploader").underscore
      end
    end
  end
end
