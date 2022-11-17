# frozen_string_literal: true

module EE
  module LfsRequest
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    LfsForbiddenError = Class.new(StandardError)

    private

    override :lfs_forbidden!
    def lfs_forbidden!
      check_free_user_cap_over_limit!

      limit_exceeded? ? render_size_error : super
    rescue LfsForbiddenError => e
      render_over_limit_error(e.message)
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

    def check_free_user_cap_over_limit!
      ::Namespaces::FreeUserCap::Enforcement.new(project.root_ancestor)
                                            .git_check_over_limit!(::LfsRequest::LfsForbiddenError) { limit_exceeded? }
    end

    def render_over_limit_error(message)
      render(
        json: {
          message: message,
          documentation_url: help_url('user/free_user_limit')
        },
        content_type: ::LfsRequest::CONTENT_TYPE,
        status: :not_acceptable
      )
    end

    def size_checker
      project.repository_size_checker
    end

    def lfs_push_size
      strong_memoize(:lfs_push_size) do
        objects.sum { |o| o[:size] }
      end
    end
  end
end
