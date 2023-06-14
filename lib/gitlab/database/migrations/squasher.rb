# frozen_string_literal: true

require 'set'

module Gitlab
  module Database
    module Migrations
      class Squasher
        INIT_SCHEMA_MATCHER = /\d{14}_init_schema.rb\z/

        def initialize(git_output)
          @migration_data = migration_files_from_git(git_output).filter_map do |mf|
            basename = Pathname(mf).basename.to_s
            file_name_match = ActiveRecord::Migration::MigrationFilenameRegexp.match(basename)
            slug = file_name_match[2]
            unless slug == 'init_schema'
              {
                path: mf,
                basename: basename,
                timestamp: file_name_match[1],
                slug: slug
              }
            end
          end
        end

        def files_to_delete
          @migration_data.pluck(:path) + schema_migrations + find_migration_specs
        end

        private

        def schema_migrations
          @migration_data.map { |m| "db/schema_migrations/#{m[:timestamp]}" }
        end

        def find_migration_specs
          file_slugs = Set.new @migration_data.pluck(:slug)
          (migration_specs + ee_migration_specs).each.select { |f| file_has_slug?(file_slugs, f) }
        end

        def migration_files_from_git(body)
          body.chomp
              .split("\n")
              .select { |fn| fn.end_with?('.rb') }
        end

        def file_has_slug?(file_slugs, filename)
          file_slugs.each do |slug|
            return true if filename.include? "#{slug}_spec.rb"
          end
          false
        end

        def migration_specs
          Dir.glob(Rails.root.join('spec/migrations/*.rb'))
        end

        def ee_migration_specs
          Dir.glob(Rails.root.join('ee/spec/migrations/*.rb'))
        end
      end
    end
  end
end
