# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SsoHelper do
  describe '#authorize_gma_conversion_confirm_modal_data' do
    let_it_be(:group_name) { 'Foo bar' }
    let_it_be(:phrase) { 'gma_user' }
    let_it_be(:remove_form_id) { 'js-authorize-gma-conversion-form' }

    subject { helper.authorize_gma_conversion_confirm_modal_data(group_name: group_name, phrase: phrase, remove_form_id: remove_form_id) }

    it 'returns expected hash' do
      expect(subject).to eq({
        remove_form_id: remove_form_id,
        button_text: _("Transfer ownership"),
        button_class: 'gl-w-full',
        confirm_danger_message: "You are about to transfer the control of your account to #{group_name} group. This action is NOT reversible, you won't be able to access any of your groups and projects outside of #{group_name} once this transfer is complete.",
        phrase: phrase
      })
    end
  end
end
