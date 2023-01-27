# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HooksHelper do
  let(:group) { create(:group) }
  let(:group_hook) { create(:group_hook, group: group) }
  let(:trigger) { 'push_events' }

  describe '#test_hook_path' do
    it 'returns group namespaced link' do
      expect(helper.test_hook_path(group_hook, trigger))
        .to eq(test_group_hook_path(group, group_hook, trigger: trigger))
    end
  end

  describe '#hook_log_path' do
    context 'with a group hook' do
      let(:web_hook_log) { create(:web_hook_log, web_hook: group_hook) }

      it 'returns group-namespaced link' do
        expect(helper.hook_log_path(group_hook, web_hook_log))
          .to eq(web_hook_log.present.details_path)
      end
    end
  end
end
