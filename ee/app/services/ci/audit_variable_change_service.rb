# frozen_string_literal: true

module Ci
  class AuditVariableChangeService < ::BaseContainerService
    include ::Audit::Changes

    AUDITABLE_VARIABLE_CLASSES = [::Ci::Variable, ::Ci::GroupVariable].freeze

    def execute
      return unless container.feature_available?(:audit_events)
      return unless AUDITABLE_VARIABLE_CLASSES.include? params[:variable].class

      case params[:action]
      when :create, :destroy
        log_audit_event(params[:action], params[:variable])
      when :update
        audit_changes(
          :protected,
          as: 'variable protection', entity: container,
          model: params[:variable], target_details: params[:variable].key,
          event_type: event_type_name(params[:variable], params[:action])
        )
      end
    end

    private

    def log_audit_event(action, variable)
      audit_context = {
        name: event_type_name(variable, action),
        author: current_user || ::Gitlab::Audit::UnauthenticatedAuthor.new,
        scope: container,
        target: variable,
        message: message(variable, action),
        additional_details: build_additional_details(variable, action)
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end

    def event_type_name(variable, action)
      name = ci_variable_name(variable)
      case action
      when :create
        "#{name}_created"
      when :destroy
        "#{name}_deleted"
      when :update
        "#{name}_updated"
      end
    end

    def message(variable, action)
      name = ci_variable_name(variable).humanize(capitalize: false)
      case action
      when :create
        "Added #{name}"
      when :destroy
        "Removed #{name}"
      end
    end

    def build_additional_details(variable, action)
      name = ci_variable_name(variable)
      case action
      when :create
        { add: name }
      when :destroy
        { remove: name }
      end
    end

    def ci_variable_name(variable)
      variable.class.to_s.parameterize(preserve_case: true).underscore
    end
  end
end
