# frozen_string_literal: true

module PreventCrossDatabaseModificationSpecHelpers
  def with_cross_database_modification_prevented(...)
    ::Gitlab::Database::PreventCrossDatabaseModification.with_cross_database_modification_prevented(...)
  end

  def cleanup_with_cross_database_modification_prevented
    ::Gitlab::Database::PreventCrossDatabaseModification.cleanup_with_cross_database_modification_prevented
  end
end

CROSS_DB_MODIFICATION_ALLOW_LIST = Set.new(YAML.load_file(File.join(__dir__, 'cross-database-modification-allowlist.yml'))).freeze

RSpec.configure do |config|
  config.include(PreventCrossDatabaseModificationSpecHelpers)

  # Using before and after blocks because the around block causes problems with the let_it_be
  # record creations. It makes an extra savepoint which breaks the transaction count logic.
  config.before do |example_file|
    if CROSS_DB_MODIFICATION_ALLOW_LIST.exclude?(example_file.file_path_rerun_argument)
      with_cross_database_modification_prevented
    end
  end

  config.after do |example_file|
    cleanup_with_cross_database_modification_prevented
  end
end
