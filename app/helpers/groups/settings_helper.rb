# frozen_string_literal: true

module Groups
  module SettingsHelper
    include GroupsHelper

    def group_settings_confirm_modal_data(group, remove_form_id = nil)
      base_data = { remove_form_id: remove_form_id, button_text: _('Remove group'), testid: 'remove-group-button' }
      base_data.merge!({ disabled: group.paid?.to_s, confirm_danger_message: remove_group_message(group), phrase: group.full_path })
    end
  end
end

Groups::SettingsHelper.prepend_mod_with('Groups::SettingsHelper')
