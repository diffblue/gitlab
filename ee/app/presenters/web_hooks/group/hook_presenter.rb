# frozen_string_literal: true

module WebHooks
  module Group
    class HookPresenter < Gitlab::View::Presenter::Delegated
      presents ::GroupHook

      def logs_details_path(log)
        group_hook_hook_log_path(group, self, log)
      end

      def logs_retry_path(log)
        retry_group_hook_hook_log_path(group, self, log)
      end
    end
  end
end
