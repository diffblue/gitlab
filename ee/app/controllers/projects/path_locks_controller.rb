# frozen_string_literal: true

class Projects::PathLocksController < Projects::ApplicationController
  include PathLocksHelper

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_read_code!
  before_action :authorize_push_code!, only: [:toggle]

  before_action :check_license

  feature_category :source_code_management
  urgency :low, [:index]

  def index
    @path_locks = @project.path_locks.page(params[:page])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def toggle
    path_lock = @project.path_locks.find_by(path: path)

    if path_lock
      unlock_file(path_lock)
    else
      lock_file
    end

    head :ok
  rescue PathLocks::UnlockService::AccessDenied, PathLocks::LockService::AccessDenied
    access_denied!
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def destroy
    path_lock = @project.path_locks.find(params[:id])

    begin
      PathLocks::UnlockService.new(project, current_user).execute(path_lock)
    rescue PathLocks::UnlockService::AccessDenied
      return access_denied!
    end

    respond_to do |format|
      format.html do
        redirect_to project_locks_path(@project), status: :found
      end
      format.js
    end
  end

  private

  def check_license
    unless @project.feature_available?(:file_locks)
      flash[:alert] = _('You need a different license to enable FileLocks feature')
      redirect_to admin_subscription_path
    end
  end

  def lock_file
    path_lock = PathLocks::LockService.new(project, current_user).execute(path)

    if path_lock.persisted? && sync_with_lfs?
      Lfs::LockFileService.new(
        project,
        current_user,
        path: path,
        create_path_lock: false
      ).execute
    end
  end

  def unlock_file(path_lock)
    PathLocks::UnlockService.new(project, current_user).execute(path_lock)

    if sync_with_lfs?
      Lfs::UnlockFileService.new(project, current_user, path: path_lock.path, force: true).execute
    end
  end

  def lfs_file?
    blob = repository.blob_at_branch(repository.root_ref, path)

    return false unless blob

    lfs_blob_ids = LfsPointersFinder.new(repository, path).execute

    lfs_blob_ids.include?(blob.id)
  end

  def sync_with_lfs?
    project.lfs_enabled? && lfs_file?
  end

  def path
    params[:path]
  end
end
