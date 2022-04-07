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
    #
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
      ::AuditEventService.new(@current_user, entity, options) # rubocop:disable Gitlab/ModuleWithInstanceVariables
        .for_changes(model).security_event
    end
  end
end
