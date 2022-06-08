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
          @protected_environment = ProtectedEnvironment.new(group: @group)
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        override :assign_variables_to_gon
        def assign_variables_to_gon
          super

          gon.push(current_group_id: group.id)
        end
      end
    end
  end
end
