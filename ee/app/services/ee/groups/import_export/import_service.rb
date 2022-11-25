# frozen_string_literal: true

module EE
  module Groups
    module ImportExport
      module ImportService
        extend ::Gitlab::Utils::Override

        override :restorers
        def restorers
          super << group_and_descendants_repo_restorer
        end

        def group_and_descendants_repo_restorer
          ::Gitlab::ImportExport::Group::GroupAndDescendantsRepoRestorer.new(group: group, shared: shared, tree_restorer: tree_restorer)
        end
      end
    end
  end
end
