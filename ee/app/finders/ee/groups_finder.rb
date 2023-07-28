# frozen_string_literal: true

module EE
  module GroupsFinder
    extend ::Gitlab::Utils::Override

    private

    override :filter_groups
    def filter_groups(groups)
      groups = super(groups)
      by_repository_storage(groups)
    end

    def by_repository_storage(groups)
      return groups if params[:repository_storage].blank?

      groups.by_repository_storage(params[:repository_storage])
    end
  end
end
