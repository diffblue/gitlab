# frozen_string_literal: true

module Audit
  class BaseChangesAuditor
    include ::Audit::Changes

    def initialize(current_user, model)
      @model = model
      @current_user = current_user
    end

    def parse_options(column, options)
      super.merge(attributes_from_auditable_model(column))
    end

    # Disables auditing when there is unintentional column change done via API params
    # for example: Project's suggestion_commit_message column is updated from nil to empty string when the user edits
    # project merge request setting even if user didn't changed the column in the form.
    def should_audit?(column)
      return false unless model.previous_changes.has_key?(column)

      from = model.previous_changes[column].first
      to = model.previous_changes[column].second
      !(from.blank? && to.blank?)
    end

    private

    def attributes_from_auditable_model(column)
      raise NotImplementedError
    end
  end
end
