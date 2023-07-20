# frozen_string_literal: true

module Gitlab
  class RootExcessSizeErrorMessage # rubocop:disable Gitlab/NamespacedClass
    include ActiveSupport::NumberHelper

    def initialize(checker, message_params = {})
      @checker = checker
      @current_size = formatted(checker.current_size)
      @size_limit = formatted(checker.limit)
      @namespace_name = message_params[:namespace_name]
    end

    def push_warning
      <<~MSG.squish
        ##### WARNING ##### You have used #{usage_percentage} of the storage quota for this project
        (#{current_size} of #{size_limit}). If a project reaches 100% of the storage quota (#{size_limit})
        the project will be in a read-only state, and you won't be able to push to your repository or add large files.
        To reduce storage usage, reduce git repository and git LFS storage. For more information about storage limits,
        see our docs: #{limit_docs_url}.
      MSG
    end

    def push_error
      <<~MSG.squish
        You have reached the free storage limit of #{repository_limit} on one or more projects.
        To unlock your projects over the free #{repository_limit} project limit, you must purchase
        additional storage. You can't push to your repository, create pipelines, create issues, or add comments.
        To reduce storage capacity, you can delete unused repositories, artifacts, wikis, issues, and pipelines.
      MSG
    end

    private

    attr_reader :checker, :current_size, :size_limit, :namespace_name

    def usage_percentage
      number_to_percentage(checker.usage_ratio * 100, precision: 0)
    end

    def limit_docs_url
      ::Gitlab::Routing.url_helpers.help_page_url('user/usage_quotas', anchor: 'project-storage-limit')
    end

    def formatted(number)
      number_to_human_size(number, delimiter: ',', precision: 2)
    end

    def repository_limit
      formatted(checker.root_namespace.actual_repository_size_limit)
    end
  end
end
