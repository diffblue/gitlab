# frozen_string_literal: true

module EE
  module Projects
    module UpdatePagesService
      extend ::Gitlab::Utils::Override

      override :pages_deployment_attributes
      def pages_deployment_attributes(file, build)
        return super unless ::Gitlab::Pages.multiple_versions_enabled_for?(build.project)

        super.merge(path_prefix: build.pages_path_prefix)
      end
    end
  end
end
