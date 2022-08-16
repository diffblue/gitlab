# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::Group::HookPresenter do
  let_it_be(:web_hook) { create(:group_hook) }
  let_it_be(:web_hook_log) { create(:web_hook_log, web_hook: web_hook) }

  let(:group) { web_hook_log.web_hook.group }

  describe '#logs_details_path' do
    subject { web_hook.present.logs_details_path(web_hook_log) }

    let(:expected_path) do
      "/groups/#{group.name}/-/hooks/#{web_hook.id}/hook_logs/#{web_hook_log.id}"
    end

    it { is_expected.to eq(expected_path) }
  end

  describe '#logs_retry_path' do
    subject { web_hook.present.logs_retry_path(web_hook_log) }

    let(:expected_path) do
      "/groups/#{group.name}/-/hooks/#{web_hook.id}/hook_logs/#{web_hook_log.id}/retry"
    end

    it { is_expected.to eq(expected_path) }
  end
end
