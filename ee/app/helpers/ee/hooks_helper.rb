# frozen_string_literal: true
module EE
  module HooksHelper
    extend ::Gitlab::Utils::Override

    override :test_hook_path
    def test_hook_path(hook, trigger)
      if hook.is_a?(GroupHook)
        test_group_hook_path(hook.group, hook, trigger: trigger)
      else
        super
      end
    end

    override :edit_hook_path
    def edit_hook_path(hook)
      if hook.is_a?(GroupHook)
        edit_group_hook_path(hook.group, hook)
      else
        super
      end
    end

    override :destroy_hook_path
    def destroy_hook_path(hook)
      if hook.is_a?(GroupHook)
        group_hook_path(hook.group, hook)
      else
        super
      end
    end

    override :hook_log_path
    def hook_log_path(hook, hook_log)
      if hook.is_a?(GroupHook)
        hook_log.present.details_path
      else
        super
      end
    end
  end
end
