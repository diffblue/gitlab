# frozen_string_literal: true

module EE
  module AuditEventService
    extend ::Gitlab::Utils::Override
    # rubocop:disable Gitlab/ModuleWithInstanceVariables

    # Builds the @details attribute for member
    #
    # @param [Member] member object being audited
    #
    # @return [AuditEventService]
    def for_member(member)
      action = @details[:action]
      old_access_level = @details[:old_access_level]
      user_id = member.id
      user_name = member.user ? member.user.name : 'Deleted User'
      target_type = 'User'

      @details =
        case action
        when :destroy
          {
            remove: "user_access",
            author_name: @author.name,
            target_id: user_id,
            target_type: target_type,
            target_details: user_name
          }
        when :expired
          {
            remove: "user_access",
            author_name: member.created_by ? member.created_by.name : 'Deleted User',
            target_id: user_id,
            target_type: target_type,
            target_details: user_name,
            system_event: true,
            reason: "access expired on #{member.expires_at}"
          }
        when :create
          {
            add: "user_access",
            as: ::Gitlab::Access.options_with_owner.key(member.access_level.to_i),
            author_name: @author.name,
            target_id: user_id,
            target_type: target_type,
            target_details: user_name
          }
        when :update, :override
          {
            change: "access_level",
            from: old_access_level,
            to: member.human_access,
            expiry_from: @details[:old_expiry],
            expiry_to: member.expires_at,
            author_name: @author.name,
            target_id: user_id,
            target_type: target_type,
            target_details: user_name
          }
        end

      self
    end

    # Builds the @details attribute for project group link
    #
    # This expects [String] :action of :destroy, :create, :update to be
    #   specified in @details attribute
    #
    # @param [ProjectGroupLink] group_link object being audited
    #
    # @return [AuditEventService]
    def for_project_group_link(group_link)
      @details = custom_project_link_group_attributes(group_link)
                 .merge(author_name: @author.name,
                        target_id: group_link.project.id,
                        target_type: 'Project',
                        target_details: group_link.project.full_path)

      self
    end

    # Builds the @details attribute for a failed login
    #
    # @return [AuditEventService]
    def for_failed_login
      auth = @details[:with] || 'STANDARD'

      @details = {
        failed_login: auth.upcase,
        author_name: @author.name,
        target_details: @author.name
      }

      self
    end

    # Builds the @details attribute for changes
    #
    # @param model [Object] the target model being audited
    #
    # @return [AuditEventService]
    def for_changes(model)
      @details =
        {
          change: @details[:as] || @details[:column],
          from: @details[:from],
          to: @details[:to],
          author_name: @author.name,
          target_id: model.id,
          target_type: model.class.name,
          target_details: @details[:target_details] || model.name
        }

      self
    end

    # Write event to file and create an event record in DB
    def security_event
      prepare_security_event

      super if enabled?
    end

    def prepare_security_event
      add_security_event_admin_details!
      add_impersonation_details!
    end

    # Creates an event record in DB
    #
    # @return [AuditEvent, nil] if record is persisted or nil if audit events
    #   features are not enabled
    def unauth_security_event
      return unless audit_events_enabled? && ::Gitlab::Database.read_write?

      add_security_event_admin_details!

      payload = {
        author_id: @author.id,
        entity_id: @entity.respond_to?(:id) ? @entity.id : -1,
        entity_type: 'User',
        details: @details
      }

      payload[:ip_address] = ip_address if admin_audit_log_enabled?

      ::AuditEvent.create(payload)
    end

    # Builds the @details attribute for user
    #
    # This uses the [User] @entity as the target object being audited
    #
    # @param [String] full_path required if it is different from the User model
    #   in @entity. This is for backward compatability and will be dropped after
    #   all of these incorrect usages are removed.
    #
    # @return [AuditEventService]
    def for_user(full_path: @entity.full_path, entity_id: @entity.id)
      for_custom_model(model: 'user', target_details: full_path, target_id: entity_id)
    end

    # Builds the @details attribute for project
    #
    # This uses the [Project] @entity as the target object being audited
    #
    # @return [AuditEventService]
    def for_project
      for_custom_model(model: 'project', target_details: @entity.full_path, target_id: @entity.id)
    end

    # Builds the @details attribute for project variable
    #
    # This uses the [Ci::ProjectVariable] @entity as the target object being audited
    #
    # @return [AuditEventService]
    def for_project_variable(project_variable_key)
      for_custom_model(model: 'ci_variable', target_details: project_variable_key, target_id: project_variable_key)
    end

    # Builds the @details attribute for group
    #
    # This uses the [Group] @entity as the target object being audited
    #
    # @return [AuditEventService]
    def for_group
      for_custom_model(model: 'group', target_details: @entity.full_path, target_id: @entity.id)
    end

    # Builds the @details attribute for group variable
    #
    # This uses the [Ci::GroupVariable] @entity as the target object being audited
    #
    # @return [AuditEventService]
    def for_group_variable(group_variable_key)
      for_custom_model(model: 'ci_group_variable', target_details: group_variable_key, target_id: group_variable_key)
    end

    def enabled?
      admin_audit_log_enabled? ||
        audit_events_enabled? ||
        entity_audit_events_enabled?
    end

    def entity_audit_events_enabled?
      @entity.respond_to?(:feature_available?) && @entity.feature_available?(:audit_events)
    end

    def audit_events_enabled?
      # Always log auth events. Log all other events if `extended_audit_events` is enabled
      @details[:with] || License.feature_available?(:extended_audit_events)
    end

    def admin_audit_log_enabled?
      License.feature_available?(:admin_audit_log)
    end

    def method_missing(method_sym, *arguments, &block)
      super(method_sym, *arguments, &block) unless respond_to?(method_sym)

      for_custom_model(model: method_sym.to_s.split('for_').last, target_details: arguments[0], target_id: arguments[1])
    end

    def respond_to?(method, include_private = false)
      method.to_s.start_with?('for_') || super
    end

    private

    override :base_payload
    def base_payload
      super.tap do |payload|
        payload[:ip_address] = ip_address if admin_audit_log_enabled?
      end
    end

    def for_custom_model(model:, target_details:, target_id:)
      action = @details[:action]
      model_class = model.camelize
      custom_message = @details[:custom_message]

      @details =
        case action
        when :destroy
          {
            remove: model,
            author_name: @author.name,
            target_id: target_id,
            target_type: model_class,
            target_details: target_details
          }
        when :create
          {
            add: model,
            author_name: @author.name,
            target_id: target_id,
            target_type: model_class,
            target_details: target_details
          }
        when :custom
          {
            custom_message: custom_message,
            author_name: @author&.name,
            target_id: target_id,
            target_type: model_class,
            target_details: target_details
          }
        end

      self
    end

    def add_security_event_admin_details!
      return unless admin_audit_log_enabled?

      @details.merge!(
        ip_address: ip_address,
        entity_path: @entity&.full_path
      )
    end

    def add_impersonation_details!
      return unless admin_audit_log_enabled?

      if @author.is_a?(::Gitlab::Audit::ImpersonatedAuthor)
        @details.merge!(impersonated_by: @author.impersonated_by)
      end
    end

    def custom_project_link_group_attributes(group_link)
      case @details[:action]
      when :destroy
        { remove: 'project_access' }
      when :create
        {
          add: 'project_access',
          as: group_link.human_access
        }
      when :update
        {
          change: 'access_level',
          from: @details[:old_access_level],
          to: group_link.human_access
        }
      end
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
  end
end
