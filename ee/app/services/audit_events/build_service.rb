# frozen_string_literal: true

module AuditEvents
  class BuildService
    # Handle missing attributes
    MissingAttributeError = Class.new(StandardError)

    # @raise [MissingAttributeError] when required attributes are blank
    #
    # @return [BuildService]
    def initialize(
      author:, scope:, target:, message:,
      created_at: DateTime.current, additional_details: {}, ip_address: nil, target_details: nil)
      raise MissingAttributeError if missing_attribute?(author, scope, target, message)

      @author = build_author(author)
      @scope = scope
      @target = build_target(target)
      @ip_address = ip_address || build_ip_address
      @message = build_message(message)
      @created_at = created_at
      @additional_details = additional_details
      @target_details = target_details
    end

    # Create an instance of AuditEvent
    #
    # @return [AuditEvent]
    def execute
      AuditEvent.new(payload)
    end

    private

    def missing_attribute?(author, scope, target, message)
      author.blank? || scope.blank? || target.blank? || message.blank?
    end

    def payload
      if License.feature_available?(:admin_audit_log)
        base_payload.merge(
          details: base_details_payload.merge(
            ip_address: @ip_address,
            entity_path: @scope.full_path,
            custom_message: @message
          ),
          ip_address: @ip_address
        )
      else
        base_payload.merge(details: base_details_payload)
      end
    end

    def base_payload
      {
        author_id: @author.id,
        author_name: @author.name,
        entity_id: @scope.id,
        entity_type: @scope.class.name,
        created_at: @created_at
      }
    end

    def base_details_payload
      @additional_details.merge({
        author_name: @author.name,
        target_id: @target.id,
        target_type: @target.type,
        target_details: @target_details || @target.details,
        custom_message: @message
      })
    end

    def build_author(author)
      author.id = -2 if author.instance_of? DeployToken

      author.impersonated? ? ::Gitlab::Audit::ImpersonatedAuthor.new(author) : author
    end

    def build_target(target)
      ::Gitlab::Audit::Target.new(target)
    end

    def build_message(message)
      if License.feature_available?(:admin_audit_log) && @author.impersonated?
        "#{message} (by #{@author.impersonated_by})"
      else
        message
      end
    end

    def build_ip_address
      Gitlab::RequestContext.instance.client_ip || @author.current_sign_in_ip
    end
  end
end
