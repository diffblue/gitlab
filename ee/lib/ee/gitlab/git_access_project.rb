# frozen_string_literal: true

module EE
  module Gitlab
    module GitAccessProject
      extend ::Gitlab::Utils::Override

      override :size_checker
      def size_checker
        root_namespace = container.namespace.root_ancestor
        if ::Namespaces::Storage::EnforcementCheckService.enforce_limit?(root_namespace)
          ::EE::Namespace::RootStorageSize.new(root_namespace)
        else
          container.repository_size_checker
        end
      end
    end
  end
end
