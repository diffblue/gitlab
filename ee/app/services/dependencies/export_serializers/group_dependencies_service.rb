# frozen_string_literal: true

module Dependencies
  module ExportSerializers
    class GroupDependenciesService
      def self.execute(dependency_list_export)
        new(dependency_list_export).execute
      end

      def initialize(dependency_list_export)
        @dependency_list_export = dependency_list_export
      end

      def execute
        [].tap do |list|
          group_dependencies.each_batch do |batch|
            list.concat(build_list_for(batch))
          end
        end
      end

      private

      attr_reader :dependency_list_export

      delegate :group, to: :dependency_list_export, private: true

      def build_list_for(batch)
        batch.with_component
             .with_source
             .with_version.map do |occurrence|
               {
                 name: occurrence.name,
                 packager: occurrence.packager,
                 version: occurrence.version,
                 location: occurrence.location
               }
             end
      end

      def group_dependencies
        ::Sbom::DependenciesFinder.new(group).execute
      end
    end
  end
end
