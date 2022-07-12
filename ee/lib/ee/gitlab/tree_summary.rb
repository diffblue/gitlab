# frozen_string_literal: true

module EE
  module Gitlab
    module TreeSummary
      extend ::Gitlab::Utils::Override

      include ::PathLocksHelper

      override :summarize
      def summarize
        super.tap { |summary| fill_path_locks!(summary) }
      end

      private

      def fill_path_locks!(entries)
        return unless project.feature_available?(:file_locks)

        finder = ::Gitlab::PathLocksFinder.new(project)
        paths = entries.map { |entry| entry_path(entry) }
        finder.preload_for_paths(paths)

        entries.each do |entry|
          path = entry_path(entry)
          path_lock = finder.find_by_path(path)

          entry[:lock_label] = path_lock && text_label_for_lock(path_lock, path)
        end
      end

      def entry_path(entry)
        File.join(*[path, entry[:file_name]].compact).force_encoding(Encoding::ASCII_8BIT)
      end
    end
  end
end
