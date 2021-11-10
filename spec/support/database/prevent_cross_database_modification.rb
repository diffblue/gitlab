# frozen_string_literal: true

module PreventCrossDatabaseModificationSpecHelpers
  delegate :with_cross_database_modification_prevented,
    :allow_cross_database_modification_within_transaction,
    to: :'::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification'
end

CROSS_DB_MODIFICATION_ALLOW_LIST = Set.new(YAML.load_file(File.join(__dir__, 'cross-database-modification-allowlist.yml'))).freeze

RSpec.configure do |config|
  config.include(PreventCrossDatabaseModificationSpecHelpers)

  # Using before and after blocks because the around block causes problems with the let_it_be
  # record creations. It makes an extra savepoint which breaks the transaction count logic.
  config.before do |example_file|
    ::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.allow_cross_database_modification =
      CROSS_DB_MODIFICATION_ALLOW_LIST.include?(example_file.file_path_rerun_argument)
  end

  config.after do |example_file|
    ::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.allow_cross_database_modification = false
  end
end
