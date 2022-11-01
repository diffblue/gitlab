# frozen_string_literal: true

module Elastic
  module MigrationObsolete
    def migrate
      log "Migration has been deleted in the last major version upgrade." \
        "Migrations are supposed to be finished before upgrading major version https://docs.gitlab.com/ee/update/#upgrading-to-a-new-major-version ." \
        "To correct this issue, recreate your index from scratch: https://docs.gitlab.com/ee/integration/advanced_search/elasticsearch_troubleshooting.html#last-resort-to-recreate-an-index."

      fail_migration_halt_error!
    end

    def completed?
      false
    end

    def obsolete?
      true
    end
  end
end
