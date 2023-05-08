# frozen_string_literal: true

class PauseIndexingForUnsupportedEsVersions < Elastic::Migration
  include Elastic::MigrationObsolete
end
