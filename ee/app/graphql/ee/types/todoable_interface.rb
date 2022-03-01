# frozen_string_literal: true

module EE
  module Types
    module TodoableInterface
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :resolve_type
        def resolve_type(object, *)
          return ::Types::EpicType if Epic === object

          super
        end
      end
    end
  end
end
