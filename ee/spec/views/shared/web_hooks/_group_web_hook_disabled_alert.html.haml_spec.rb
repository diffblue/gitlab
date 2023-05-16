# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/web_hooks/_group_web_hook_disabled_alert', feature_category: :webhooks do
  let_it_be(:group) { build_stubbed(:group) }

  def after_flash_content
    view.content_for(:after_flash_content)
  end

  before do
    view.assign(group: group)
    allow(view).to receive(:show_group_hook_failed_callout?).with(group: group).and_return(show_callout)
  end

  context 'when the helper returns true' do
    let(:show_callout) { true }

    it 'adds alert to `:after_flash_content`' do
      view.render('shared/web_hooks/group_web_hook_disabled_alert')

      expect(after_flash_content).to have_content('Webhook disabled')
    end
  end

  context 'when helper returns false' do
    let(:show_callout) { false }

    it 'does not add alert to `:after_flash_content`' do
      view.render('shared/web_hooks/group_web_hook_disabled_alert')

      expect(after_flash_content).to be_nil
    end
  end
end
