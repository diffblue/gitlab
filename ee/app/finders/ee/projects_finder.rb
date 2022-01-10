# frozen_string_literal: true

module EE
  # ProjectsFinder
  #
  # Extends ProjectsFinder
  #
  # Added arguments:
  #   params:
  #     plans: string[]
  module ProjectsFinder
    extend ::Gitlab::Utils::Override

    private

    override :filter_projects
    def filter_projects(collection)
      collection = super(collection)
      collection = by_plans(collection)
      collection = by_feature_available(collection)
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
        collection.with_feature(feature)
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
  end
end
