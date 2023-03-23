# frozen_string_literal: true

module MergeRequests
  class UpdateBlocksService
    include ::Gitlab::Allowable
    include ::Gitlab::Utils::StrongMemoize

    class << self
      def extract_params!(mutable_params)
        {
          update: mutable_params.delete(:update_blocking_merge_request_refs),
          remove_hidden: mutable_params.delete(:remove_hidden_blocking_merge_requests),
          references: mutable_params.delete(:blocking_merge_request_references)
        }
      end
    end

    attr_reader :merge_request, :current_user, :params

    def initialize(merge_request, current_user, params = {})
      @merge_request = merge_request
      @current_user = current_user
      @params = params

      DeclarativePolicy.user_scope do
        @visible_blocks, @hidden_blocks = merge_request.blocks_as_blockee.partition do |block|
          can?(current_user, :read_merge_request, block.blocking_merge_request)
        end
      end
    end

    def execute
      return unless update?
      return unless merge_request.target_project.feature_available?(:blocking_merge_requests)

      previous_blocking_merge_requests = merge_request.blocking_merge_requests.to_a

      valid_references, invalid_references = extract_references

      delete_old_blockers!(valid_references)

      errors = create_blockers(valid_references)

      if invalid_references.present?
        merge_request.errors.add(:dependencies, 'failed to save: ' + invalid_references.join(', '))
      end

      if errors.present?
        docs_link =
          Rails
            .application
            .routes
            .url_helpers
            .help_page_url(
              'user/project/merge_requests/dependencies.html',
              anchor: 'complex-merge-order-dependencies-are-unsupported'
            )

        merge_request
          .errors
          .add(
            :dependencies,
            'failed to save: ' + errors.uniq.join(', ') + '.',
            help_page_url: docs_link
          )
      end

      # When no references are specified and old blocking merge requests are deleted,
      # we need to reset the associations so we can get the updated state of association.
      # This is because blocking merge requests are deleted via `delete_all`.
      if merge_request.blocking_merge_requests.reset != previous_blocking_merge_requests
        GraphqlTriggers.merge_request_merge_status_updated(merge_request)
      end

      true
    end

    private

    attr_reader :visible_blocks, :hidden_blocks

    def update?
      params.fetch(:update, false)
    end

    def remove_hidden?
      params.fetch(:remove_hidden, false)
    end

    def references
      params.fetch(:references, [])
    end

    # Returns two lists of references separating valid from invalid ones
    #
    # @return [Array<Array>] an array of valid and an array of invalid references
    def extract_references
      invalid_references = []
      valid_references = []

      return [], [] unless references.present?

      # The analyzer will only return references the current user can see
      references.each do |reference|
        analyzer = ::Gitlab::ReferenceExtractor.new(merge_request.target_project, current_user)
        analyzer.analyze(reference)

        if analyzer.merge_requests.any?
          valid_references << analyzer.merge_requests
        else
          invalid_references << reference
        end
      end

      [valid_references.flatten.map(&:id), invalid_references]
    end

    def delete_old_blockers!(valid_references)
      merge_request
        .blocks_as_blockee
        .with_blocking_mr_ids(ids_to_delete(valid_references))
        .delete_all
    end

    def create_blockers(valid_references)
      new_ids = ids_to_add(valid_references)

      new_ids.each_with_object([]) do |blocking_id, errors|
        blocked = ::MergeRequestBlock.create(
          blocking_merge_request_id: blocking_id,
          blocked_merge_request_id: merge_request.id
        )

        unless blocked.persisted?
          errors << blocked.errors.full_messages
        end
      end
    end

    def ids_to_add(valid_references)
      valid_references - visible_ids
    end

    def ids_to_delete(valid_references)
      (visible_ids - valid_references).tap do |ary|
        ary.push(*hidden_ids) if remove_hidden?
      end
    end

    def visible_ids
      strong_memoize(:visible_ids) { visible_blocks.map(&:blocking_merge_request_id) }
    end

    def hidden_ids
      hidden_blocks.map(&:blocking_merge_request_id)
    end
  end
end
