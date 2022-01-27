# frozen_string_literal: true

module Issues
  class ReorderService < Issues::BaseService
    def execute(issue)
      return false unless can?(current_user, :update_issue, issue)

      attrs = issue_params
      return false if attrs.empty?

      update(issue, attrs)
    end

    private

    def update(issue, attrs)
      ::Issues::UpdateService.new(project: project, current_user: current_user, params: attrs).execute(issue)
    rescue ActiveRecord::RecordNotFound
      false
    end

    def issue_params
      attrs = {}

      if move_between_ids
        attrs[:move_between_ids] = move_between_ids
      end

      attrs
    end

    def move_between_ids
      ids = [params[:move_after_id], params[:move_before_id]]
              .map(&:to_i)
              .map { |m| m > 0 ? m : nil }

      ids.any? ? ids : nil
    end
  end
end
