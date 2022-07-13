# frozen_string_literal: true

module Audit
  module Changes
    # Records an audit event in DB for model changes
    #
    # @param [Symbol] column column name to be audited
    # @param [Hash] options the options to create an event with
    # @option options [Symbol] :column column name to be audited
    # @option options [User, Project, Group] :target_model scope the event belongs to
    # @option options [Object] :model object being audited
    # @option options [Boolean] :skip_changes whether to record from/to values
    # @option options [String] :event_type adds event type in streaming audit event headers and payload
    # @return [AuditEvent, nil] the resulting object or nil if there is no
    #   change detected
    def audit_changes(column, options = {})
      column = options[:column] || column
      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      @entity = options[:entity]
      @model = options[:model]
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      return unless audit_required?(column)

      audit_event(parse_options(column, options))
    end

    protected

    def entity
      @entity || model # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def model
      @model
    end

    private

    def audit_required?(column)
      not_recently_created? && changed?(column)
    end

    def not_recently_created?
      !model.previous_changes.has_key?(:id)
    end

    def changed?(column)
      model.previous_changes.has_key?(column)
    end

    def changes(column)
      model.previous_changes[column]
    end

    def parse_options(column, options)
      options.tap do |options_hash|
        options_hash[:column] = column
        options_hash[:action] = :update

        unless options[:skip_changes]
          options_hash[:from] = changes(column).first
          options_hash[:to] = changes(column).last
        end
      end
    end

    def audit_event(options)
      return unless audit_enabled?

      name = options.fetch(:event_type, 'audit_operation')
      details = additional_details(options)
      audit_context = {
        name: name,
        author: @current_user, # rubocop:disable Gitlab/ModuleWithInstanceVariables
        scope: entity,
        target: model,
        message: build_message(details),
        additional_details: details,
        target_details: options[:target_details]
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end

    def additional_details(options)
      { change: options[:as] || options[:column] }.merge(options.slice(:from, :to, :target_details))
    end

    def build_message(details)
      message = ["Changed #{details[:change]}"]
      message << "from #{details[:from]}" if details[:from].to_s.present?
      message << "to #{details[:to]}" if details[:to].to_s.present?
      message.join(' ')
    end

    # TODO: Remove this once we implement license feature checks in Auditor.
    # issue link: https://gitlab.com/gitlab-org/gitlab/-/issues/365441
    def audit_enabled?
      return true if ::License.feature_available?(:admin_audit_log)
      return true if ::License.feature_available?(:extended_audit_events)

      entity.respond_to?(:feature_available?) && entity.licensed_feature_available?(:audit_events)
    end
  end
end
