# frozen_string_literal: true

module EE
  # ProjectsFinder
  #
  # Extends ProjectsFinder
  #
  # Added arguments:
  #   params:
  #     plans: string[]
  #     feature_available: string[]
  #     aimed_for_deletion: Symbol
  #     include_hidden: boolean
  module ProjectsFinder
    extend ::Gitlab::Utils::Override

    private

    override :filter_projects
    def filter_projects(collection)
      collection = super(collection)
      collection = by_plans(collection)
      collection = by_feature_available(collection)
      collection = by_hidden(collection)
      by_aimed_for_deletion(collection)
    end

    def by_plans(collection)
      if names = params[:plans].presence
        collection.for_plan_name(names)
      else
        collection
      end
    end

    def by_feature_available(collection)
      if feature = params[:feature_available].presence
        collection.with_feature_available(feature)
      else
        collection
      end
    end

    def by_aimed_for_deletion(items)
      if ::Gitlab::Utils.to_boolean(params[:aimed_for_deletion])
        items.aimed_for_deletion(Date.current)
      else
        items
      end
    end

    def by_hidden(items)
      params[:include_hidden].present? ? items : items.not_hidden
    end
  end
end
