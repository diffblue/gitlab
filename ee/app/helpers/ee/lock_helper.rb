# frozen_string_literal: true

module EE
  module LockHelper
    DEFAULT_CSS_CLASSES = 'path-lock js-path-lock js-hide-on-root hidden'

    def lock_file_link(project = @project, path = @path)
      return unless project.feature_available?(:file_locks)
      return unless current_user

      path_lock = project.find_path_lock(path, downstream: true)

      if path_lock
        locker = path_lock.user.name

        if path_lock.exact?(path)
          exact_lock_file_link(path_lock, locker)
        elsif path_lock.upstream?(path)
          upstream_lock_file_link(path_lock, locker)
        elsif path_lock.downstream?(path)
          downstream_lock_file_link(path_lock, locker)
        end
      else
        _lock_link(current_user, project)
      end
    end

    private

    def exact_lock_file_link(path_lock, locker)
      if can_unlock?(path_lock)
        tooltip = path_lock.user == current_user ? '' : "Locked by #{locker}"
        enabled_lock_link("Unlock", tooltip, :unlock)
      else
        disabled_lock_link("Unlock", "Locked by #{locker}. You do not have permission to unlock this")
      end
    end

    def upstream_lock_file_link(path_lock, locker)
      additional_phrase = can_unlock?(path_lock) ? 'Unlock that directory in order to unlock this' : 'You do not have permission to unlock it'
      disabled_lock_link("Unlock", "#{locker} has a lock on \"#{path_lock.path}\". #{additional_phrase}")
    end

    def downstream_lock_file_link(path_lock, locker)
      additional_phrase = can_unlock?(path_lock) ? 'Unlock this in order to proceed' : 'You do not have permission to unlock it'
      disabled_lock_link("Lock", "This directory cannot be locked while #{locker} has a lock on \"#{path_lock.path}\". #{additional_phrase}")
    end

    def _lock_link(user, project)
      if can?(current_user, :push_code, project)
        enabled_lock_link("Lock", '', :lock)
      else
        disabled_lock_link("Lock", "You do not have permission to lock this")
      end
    end

    def disabled_lock_link(label, title)
      # Disabled buttons with tooltips should have the tooltip attached
      # to a wrapper element https://bootstrap-vue.org/docs/components/tooltip#disabled-elements
      button = render Pajamas::ButtonComponent.new(disabled: true, button_options: { class: DEFAULT_CSS_CLASSES, data: { qa_selector: 'disabled_lock_button' } }) do
        label
      end
      content_tag(:span, button, title: title, class: 'btn-group has-tooltip')
    end

    def enabled_lock_link(label, title, state)
      render Pajamas::ButtonComponent.new(href: '#', button_options: { class: "#{DEFAULT_CSS_CLASSES} has-tooltip", title: title, data: { state: state, toggle: 'tooltip', qa_selector: 'lock_button' } }) do
        label
      end
    end
  end
end
