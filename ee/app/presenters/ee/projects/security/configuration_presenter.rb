# frozen_string_literal: true

module EE
  module Projects
    module Security
      module ConfigurationPresenter
        extend ::Gitlab::Utils::Override

        private

        override :can_toggle_autofix
        def can_toggle_autofix
          try(:auto_fix_permission)
        end

        override :autofix_enabled
        def autofix_enabled
          {
            dependency_scanning: project_settings&.auto_fix_dependency_scanning,
            container_scanning: project_settings&.auto_fix_container_scanning
          }
        end

        override :auto_fix_user_path
        def auto_fix_user_path
          '/' # TODO: real link will be updated with https://gitlab.com/gitlab-org/gitlab/-/issues/348463
        end
      end
    end
  end
end
