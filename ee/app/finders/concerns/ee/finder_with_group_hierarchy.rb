# frozen_string_literal: true

module EE
  module FinderWithGroupHierarchy
    def preload_associations(groups)
      super

      ::Gitlab::GroupPlansPreloader.new.preload(groups) # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
