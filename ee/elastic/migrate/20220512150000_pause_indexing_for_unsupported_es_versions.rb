# frozen_string_literal: true

class PauseIndexingForUnsupportedEsVersions < Elastic::Migration
  def migrate
    return if Gitlab::CurrentSettings.elasticsearch_pause_indexing?
    return if helper.supported_version?

    log "You're using an unsupported Elasticsearch version. " \
        "Please upgrade to a supported version. Pausing indexing to prevent losing indexing updates."

    Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: true)
  end

  def completed?
    true
  end
end
