# frozen_string_literal: true

module EE
  module Groups
    module ImportExport
      module ExportService
        extend ::Gitlab::Utils::Override

        override :savers
        def savers
          super << group_and_descendants_repo_saver
        end

        def group_and_descendants_repo_saver
          ::Gitlab::ImportExport::Group::GroupAndDescendantsRepoSaver.new(group: group, shared: shared)
        end
      end
    end
  end
end
