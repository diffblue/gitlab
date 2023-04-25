# frozen_string_literal: true

module EE
  module TodoService
    extend ::Gitlab::Utils::Override

    # When new approvers are added for a merge request:
    #
    #  * create a todo for those users to approve the MR
    #
    def add_merge_request_approvers(merge_request, approvers)
      create_approval_required_todos(merge_request, approvers, merge_request.author)
    end

    override :new_merge_request
    def new_merge_request(merge_request, author)
      unless ::Feature.enabled?(:no_todo_for_approvers, merge_request.target_project)
        approvers = merge_request.overall_approvers(exclude_code_owners: true)
        create_approval_required_todos(merge_request, approvers, author)
      end

      super
    end

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

    private

    override :attributes_for_target
    def attributes_for_target(target)
      attributes = super

      if target.is_a?(Epic)
        attributes[:group_id] = target.group_id
      end

      attributes
    end

    def create_approval_required_todos(merge_request, approvers, author)
      project = merge_request.project
      attributes = attributes_for_todo(project, merge_request, author, ::Todo::APPROVAL_REQUIRED)

      # Preload project_authorizations to prevent n+1 queries
      merge_request.project.team.max_member_access_for_user_ids(approvers.map(&:id))

      approvers = approvers.select do |approver|
        approver.can?(:approve_merge_request, merge_request)
      end

      create_todos(approvers, attributes, project.namespace, project)
    end

    def create_merge_train_removed_todo(merge_request, user)
      project = merge_request.project
      attributes = attributes_for_todo(project, merge_request, user, ::Todo::MERGE_TRAIN_REMOVED)
      create_todos(user, attributes, project.namespace, project)
    end
  end
end
