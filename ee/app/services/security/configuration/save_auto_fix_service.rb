# frozen_string_literal: true

module Security
  module Configuration
    class SaveAutoFixService
      SUPPORTED_SCANNERS = %w(container_scanning dependency_scanning all).freeze

      # @param project [Project]
      # @param ['dependency_scanning', 'container_scanning', 'all'] feature Type of scanner to apply auto_fix
      def initialize(project, feature)
        @project = project
        @feature = feature
      end

      def execute(enabled:)
        return error("Auto fix is not available for #{feature} feature") unless valid?
        return error("Project has no security setting") unless setting

        if setting&.update(toggle_params(enabled))
          success(updated_setting)
        else
          error('Error during updating the auto fix param')
        end
      end

      private

      attr_reader :enabled, :feature, :project

      def error(message)
        ServiceResponse.error(message: message)
      end

      def setting
        @setting ||= project&.security_setting
      end

      def success(payload)
        ServiceResponse.success(payload: payload)
      end

      def toggle_params(enabled)
        if feature == 'all'
          {
            auto_fix_container_scanning: enabled,
            auto_fix_dast: enabled,
            auto_fix_dependency_scanning: enabled,
            auto_fix_sast: enabled
          }
        else
          {
            "auto_fix_#{feature}" => enabled
          }
        end
      end

      def updated_setting
        {
          container_scanning: setting.auto_fix_container_scanning,
          dependency_scanning: setting.auto_fix_dependency_scanning
        }
      end

      def valid?
        SUPPORTED_SCANNERS.include?(feature)
      end
    end
  end
end
