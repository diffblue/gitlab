# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::HookLogsController do
  let(:user) { create(:user) }
  let(:web_hook_log) { create(:web_hook_log, web_hook: web_hook) }
  let(:web_hook) { create(:group_hook) }
  let(:log_params) do
    {
      group_id: web_hook.group.path,
      hook_id: web_hook.id,
      id: web_hook_log.id
    }
  end

  before do
    sign_in(user)
    web_hook.group.add_owner(user)
  end

  describe 'GET #show' do
    it 'renders a 200 if the hook exists' do
      get group_hook_hook_log_path(log_params)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('groups/hook_logs/show')
    end

    it 'renders a 404 if the hook does not exist' do
      web_hook.destroy!
      get group_hook_hook_log_path(log_params)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'POST #retry' do
    it 'executes the hook and redirects to the service form' do
      stub_request(:post, web_hook.url)

      expect_next_found_instance_of(GroupHook) do |hook|
        expect(hook).to receive(:execute).and_call_original
      end

      post retry_group_hook_hook_log_path(log_params)

      expect(response).to redirect_to(edit_group_hook_url(web_hook.group, web_hook))
    end

    it 'renders a 404 if the hook does not exist' do
      web_hook.destroy!
      post retry_group_hook_hook_log_path(log_params)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
