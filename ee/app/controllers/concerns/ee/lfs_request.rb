# frozen_string_literal: true

module EE
  module LfsRequest
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    private

    override :lfs_forbidden!
    def lfs_forbidden!
      limit_exceeded? ? render_size_error : super
    end

    override :limit_exceeded?
    def limit_exceeded?
      strong_memoize(:limit_exceeded) do
        size_checker.changes_will_exceed_size_limit?(lfs_push_size)
      end
    end

    def render_size_error
      render(
        json: {
          message: size_checker.error_message.push_error(lfs_push_size),
          documentation_url: help_url
        },
        content_type: ::LfsRequest::CONTENT_TYPE,
        status: :not_acceptable
      )
    end

    def size_checker
      root_namespace = project.namespace.root_ancestor
      if ::EE::Gitlab::Namespaces::Storage::Enforcement.enforce_limit?(root_namespace)
        EE::Namespace::RootStorageSize.new(root_namespace)
      else
        project.repository_size_checker
      end
    end

    def lfs_push_size
      strong_memoize(:lfs_push_size) do
        objects.sum { |o| o[:size] }
      end
    end
  end
end
