# frozen_string_literal: true

module EE
  module ContainerRegistry
    module Event
      extend ::Gitlab::Utils::Override

      override :handle!
      def handle!
        super
        handle_after_update!
      end

      private

      def handle_after_update!
        return unless media_type_manifest? || target_tag?
        return unless container_repository_exists?

        container_repository = find_container_repository!
        container_repository.replicator.handle_after_update
      end

      def media_type_manifest?
        event.dig('target', 'mediaType')&.include?('manifest')
      end

      def find_container_repository!
        ::ContainerRepository.find_by_path!(container_registry_path)
      end
    end
  end
end
