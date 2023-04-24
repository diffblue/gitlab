# frozen_string_literal: true

module EE
  module RequireMigration
    extend ActiveSupport::Concern

    MIGRATION_FOLDERS = %w[
      ee/db/embedding/migrate
      ee/db/embedding/post_migrate
      ee/db/geo/migrate
      ee/db/geo/post_migrate
    ].freeze

    class_methods do
      def migration_folders
        @migration_folders ||= super + MIGRATION_FOLDERS
      end
    end
  end
end
