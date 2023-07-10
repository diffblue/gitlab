# frozen_string_literal: true

module PathLocksHelper
  def can_unlock?(path_lock, current_user = @current_user)
    can?(current_user, :admin_path_locks, path_lock)
  end

  def text_label_for_lock(file_lock, path)
    if file_lock.path == path
      "Locked by #{file_lock.user.username}"
    else
      # Nested lock
      "#{file_lock.user.username} has a lock on \"#{file_lock.path}\""
    end
  end
end
