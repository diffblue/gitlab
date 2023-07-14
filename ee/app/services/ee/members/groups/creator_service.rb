# frozen_string_literal: true

module EE
  module Members
    module Groups
      module CreatorService
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        class_methods do
          extend ::Gitlab::Utils::Override

          private

          override :parsed_args
          def parsed_args(args)
            super.merge(ignore_user_limits: args[:ignore_user_limits])
          end
        end

        private

        override :member_attributes
        def member_attributes
          super.merge(ignore_user_limits: ignore_user_limits)
        end

        def ignore_user_limits
          args[:ignore_user_limits]
        end
      end
    end
  end
end
