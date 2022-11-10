# frozen_string_literal: true

module EE
  module Gitlab
    module GitalyClient
      module WithFeatureFlagActors
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        override :group_actor
        def group_actor
          strong_memoize(:group_actor) do
            if repository_container.is_a?(::GroupWiki)
              ::Feature::Gitaly::ActorWrapper.new(::Group, repository_container.id)
            else
              ::Feature::Gitaly.group_actor(repository_container)
            end
          end
        end
      end
    end
  end
end
