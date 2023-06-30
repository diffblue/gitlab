# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Utils
        class Authorizer
          def self.context_authorized?(context:)
            if context.resource && context.container
              resource_authorized?(resource: context.resource,
                user: context.current_user) && container_authorized?(container: context.container)
            elsif context.resource
              resource_authorized?(resource: context.resource, user: context.current_user)
            elsif context.container
              container_authorized?(container: context.container)
            else
              user_authorized?(user: context.current_user)
            end
          end

          def self.container_authorized?(container:)
            Gitlab::Llm::StageCheck.available?(container, :chat)
          end

          def self.resource_authorized?(resource:, user:)
            return unless resource
            return user_authorized?(user: user) if resource == user

            container = resource&.resource_parent&.root_ancestor
            return false if !container || !container_authorized?(container: container)

            user.can?("read_#{resource.to_ability_name}", resource)
          end

          def self.user_authorized?(user:)
            user.any_group_with_ai_available?
          end
        end
      end
    end
  end
end
