# frozen_string_literal: true

module EE
  module Groups
    module Settings
      module CiCdController
        extend ::Gitlab::Utils::Override

        override :push_licensed_features
        def push_licensed_features
          push_licensed_feature(:group_scoped_ci_variables, group)
        end

        override :define_variables
        def define_variables
          super

          define_protected_env_variables
        end

        private

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        def define_protected_env_variables
          @protected_environments = @group.protected_environments.sorted_by_name
          @protected_environment = ProtectedEnvironment.new(group: @group)
          @tiers = ::Environment.tiers.except(*names_for(@protected_environments))
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        # rubocop:disable CodeReuse/ActiveRecord
        def names_for(protected_environments)
          protected_environments.pluck(:name).map(&:to_sym)
        end
        # rubocop:enable CodeReuse/ActiveRecord

        override :assign_variables_to_gon
        def assign_variables_to_gon
          super

          gon.push(current_group_id: group.id)
        end
      end
    end
  end
end
