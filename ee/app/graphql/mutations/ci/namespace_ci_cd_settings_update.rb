# frozen_string_literal: true

module Mutations
  module Ci
    class NamespaceCiCdSettingsUpdate < BaseMutation
      graphql_name 'NamespaceCiCdSettingsUpdate'

      include ResolvesNamespace

      authorize :admin_namespace

      argument :allow_stale_runner_pruning, GraphQL::Types::Boolean,
        required: false,
        description: copy_field_description(Types::Ci::NamespaceCiCdSettingType, :allow_stale_runner_pruning)
      argument :full_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the namespace the settings belong to.'

      field :ci_cd_settings,
        Types::Ci::NamespaceCiCdSettingType,
        null: false,
        description: 'CI/CD settings after mutation.'

      def resolve(full_path:, **args)
        namespace = authorized_find!(full_path)
        # rubocop:disable CodeReuse/ActiveRecord
        settings = ::NamespaceCiCdSetting.find_or_initialize_by(namespace_id: namespace.id)
        # rubocop:enable CodeReuse/ActiveRecord
        settings.update(args)

        {
          ci_cd_settings: settings,
          errors: errors_on_object(settings)
        }
      end

      private

      def find_object(full_path)
        resolve_namespace(full_path: full_path)
      end
    end
  end
end
