# frozen_string_literal: true

module Audit
  class Details
    ACTIONS = %i[add remove failed_login change updated_ref custom_message].freeze

    def self.humanize(...)
      new(...).humanize
    end

    def initialize(details)
      @details = details
    end

    def humanize
      if @details[:with]
        "Signed in with #{@details[:with].upcase} authentication"
      elsif event_created_by_system?
        "#{action_text} via system job. Reason: #{@details[:reason]}"
      elsif impersonated_event?
        "#{action_text} (by #{@details[:impersonated_by]})"
      else
        action_text
      end
    end

    private

    def event_created_by_system?
      @details[:system_event]
    end

    def impersonated_event?
      @details[:impersonated_by].present?
    end

    def action_text
      action_name, action_info = @details.slice(*ACTIONS).first

      case action_name
      when :add
        "Added #{target_name}#{@details[:as] ? " as #{@details[:as]}" : ''}"
      when :remove
        "Removed #{target_name}"
      when :failed_login
        "Failed to login with #{oauth_label} authentication"
      when :updated_ref
        target_ref = @details[:updated_ref]
        from_sha = @details[:from]
        to_sha = @details[:to]

        "Updated ref #{target_ref} from #{from_sha} to #{to_sha}"
      when :custom_message
        action_info
      else
        text_for_change(target_name)
      end
    end

    def text_for_change(value)
      changed = ["Changed #{value}"]

      changed << "from #{@details[:from]}" if @details[:from].to_s.present?
      changed << "to #{@details[:to]}" if @details[:to].to_s.present?

      if access_level_changed?(value) && expiry_details_available?
        changed << text_for_expiry_change
      end

      changed.join(' ')
    end

    # this check is made in order to not show expiry details for older audit events
    # that has been logged *without* these keys.
    def expiry_details_available?
      @details.has_key?(:expiry_from) && @details.has_key?(:expiry_to)
    end

    def text_for_expiry_change
      old_expiry = @details[:expiry_from].presence || never_expires_text
      new_expiry = @details[:expiry_to].presence || never_expires_text

      if expiry_changed?(old_expiry, new_expiry)
        _('with expiry changing from %{old_expiry} to %{new_expiry}') %
          { old_expiry: old_expiry, new_expiry: new_expiry }
      else
        _('with expiry remaining unchanged at %{old_expiry}') % { old_expiry: old_expiry }
      end
    end

    def never_expires_text
      _('never expires')
    end

    def expiry_changed?(old_expiry, new_expiry)
      new_expiry != old_expiry
    end

    def access_level_changed?(value)
      value == 'access level'
    end

    def target_name
      @details[:target_type] == 'Operations::FeatureFlag' ? detail_value : target_name_with_space
    end

    def target_name_with_space
      detail_value.tr('_', ' ')
    end

    def detail_value
      String(@details.each_value.first)
    end

    def oauth_label
      Gitlab::Auth::OAuth::Provider.label_for(detail_value).upcase
    end
  end
end
