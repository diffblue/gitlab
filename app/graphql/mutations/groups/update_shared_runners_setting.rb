# frozen_string_literal: true

module Mutations
  module Groups
    class UpdateSharedRunnersSetting < Mutations::BaseMutation
      include Mutations::ResolvesGroup

      graphql_name 'GroupSharedRunnersSettingUpdate'

      authorize :update_group_shared_runners_setting

      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the group that will be updated.'
      argument :shared_runners_setting, Types::Namespace::SharedRunnersSettingEnum,
               required: true,
               description: copy_field_description(Types::GroupType, :shared_runners_setting)

      def resolve(full_path:, **args)
        group = authorized_find!(full_path: full_path)

        result = ::Groups::UpdateSharedRunnersService
          .new(group, current_user, args)
          .execute

        {
          errors: result[:status] == :success ? [] : Array.wrap(result[:message])
        }
      end

      private

      def find_object(full_path:)
        resolve_group(full_path: full_path)
      end
    end
  end
end
