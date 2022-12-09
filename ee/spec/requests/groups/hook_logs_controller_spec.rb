# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::HookLogsController, feature_category: :integrations do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:web_hook) { create(:group_hook) }
  let_it_be_with_refind(:web_hook_log) { create(:web_hook_log, web_hook: web_hook) }

  let(:group) { web_hook.group }

  it_behaves_like WebHooks::HookLogActions do
    let(:edit_hook_path) { edit_group_hook_url(group, web_hook) }

    before do
      group.add_owner(user)
    end
  end
end
