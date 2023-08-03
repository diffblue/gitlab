# frozen_string_literal: true

module EE
  module TodoService
    extend ::Gitlab::Utils::Override

    def new_epic(epic, current_user)
      create_mention_todos(nil, epic, current_user)
    end

    def update_epic(epic, current_user, skip_users = [])
      update_issuable(epic, current_user, skip_users)
    end

    # When a merge train is aborted for some reason, we should:
    #
    #  * create a todo for each merge request participant
    #
    def merge_train_removed(merge_request)
      merge_request.merge_participants.each do |user|
        create_merge_train_removed_todo(merge_request, user)
      end
    end

    def review_submitted(review)
      merge_request = review.merge_request

      # We don't need to create a To-Do for the review author if they added a
      # review for their own merge request.
      return if merge_request.author == review.author

      project = merge_request.project
      attributes = attributes_for_todo(project, merge_request, review.author, ::Todo::REVIEW_SUBMITTED)
      create_todos(merge_request.author, attributes, project.namespace, project)
    end

    private

    override :attributes_for_target
    def attributes_for_target(target)
      attributes = super

      if target.is_a?(Epic)
        attributes[:group_id] = target.group_id
      end

      attributes
    end

    def create_merge_train_removed_todo(merge_request, user)
      project = merge_request.project
      attributes = attributes_for_todo(project, merge_request, user, ::Todo::MERGE_TRAIN_REMOVED)
      create_todos(user, attributes, project.namespace, project)
    end
  end
end
