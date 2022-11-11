# frozen_string_literal: true

module CredentialsInventoryActions
  extend ActiveSupport::Concern
  include CredentialsInventoryHelper

  def index
    @credentials = filter_credentials.page(params[:page]).preload_users.without_count # rubocop:disable Gitlab/ModuleWithInstanceVariables

    respond_to do |format|
      format.html do
        render 'shared/credentials_inventory/index'
      end
    end
  end

  def destroy
    key = KeysFinder.new({ users: users, key_type: 'ssh' }).find_by_id(params[:id])

    return render_404 if key.nil?

    alert = if Keys::DestroyService.new(current_user).execute(key)
              notify_deleted_or_revoked_credential(key)
              _('User key was successfully removed.')
            else
              _('Failed to remove user key.')
            end

    redirect_to credentials_inventory_path(filter: 'ssh_keys'), status: :found, notice: alert
  end

  def revoke
    personal_access_token = personal_access_token_finder.find_by_id(params[:id] || params[:credential_id])
    return render_404 unless personal_access_token
    return render_404 if params[:resource_id] && !resource_type

    result = revoke_service(
      personal_access_token,
      resource_type: resource_type,
      resource_id: params[:resource_id]
    ).execute

    if result.success?
      flash[:notice] = result.message
      notify_deleted_or_revoked_credential(personal_access_token)
    else
      flash[:alert] = result.message
    end

    redirect_to credentials_inventory_path(page: params[:page])
  end

  private

  def filter_credentials
    if show_personal_access_tokens?
      ::PersonalAccessTokensFinder.new({ users: users, impersonation: false, sort: 'id_desc', owner_type: 'human' }).execute
    elsif show_ssh_keys?
      ::KeysFinder.new({ users: users, key_type: 'ssh' }).execute
    elsif show_resource_access_tokens?
      ::PersonalAccessTokensFinder.new(users: users, impersonation: false, sort: 'id_desc').execute.project_access_token
    end
  end

  def notify_deleted_or_revoked_credential(credential)
    case credential
    when Key
      CredentialsInventoryMailer.ssh_key_deleted_email(
        params: {
          notification_email: credential.user.notification_email_or_default,
          title: credential.title,
          last_used_at: credential.last_used_at,
          created_at: credential.created_at
        }, deleted_by: current_user
      ).deliver_later
    when PersonalAccessToken
      CredentialsInventoryMailer.personal_access_token_revoked_email(token: credential, revoked_by: current_user).deliver_later
    end
  end

  def personal_access_token_finder
    if revocable.instance_of?(Group)
      ::PersonalAccessTokensFinder.new({ impersonation: false, users: users })
    else
      ::PersonalAccessTokensFinder.new({ impersonation: false }, current_user)
    end
  end

  def resource_type
    type = params[:resource_type]
    return unless type == "Group" || type == "Project"

    type.constantize
  end

  def revoke_service(token, resource_id: nil, resource_type: nil)
    return ::ResourceAccessTokens::RevokeService.new(current_user, resource_type.find_by_id(resource_id), token) if resource_id

    if revocable.instance_of?(Group)
      ::PersonalAccessTokens::RevokeService.new(current_user, token: token, group: revocable)
    else
      ::PersonalAccessTokens::RevokeService.new(current_user, token: token)
    end
  end

  def users
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def revocable
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end
end
