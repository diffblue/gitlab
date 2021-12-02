# frozen_string_literal: true

module Groups::SsoHelper
  def transfer_ownership_message(group_name)
    _("You are about to transfer the control of your account to %{group_name} group. This action is NOT reversible, you won't be able to access any of your groups and projects outside of %{group_name} once this transfer is complete.") %
    { group_name: sanitize(group_name) }
  end

  def authorize_gma_conversion_confirm_modal_data(group_name:, phrase:, remove_form_id:)
    {
      remove_form_id: remove_form_id,
      button_text: _("Transfer ownership"),
      button_class: 'gl-w-full',
      confirm_danger_message: transfer_ownership_message(group_name),
      phrase: phrase
    }
  end
end
