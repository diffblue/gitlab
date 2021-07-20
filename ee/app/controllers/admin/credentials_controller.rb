# frozen_string_literal: true

class Admin::CredentialsController < Admin::ApplicationController
  extend ::Gitlab::Utils::Override
  include CredentialsInventoryActions
  include RedisTracking

  helper_method :credentials_inventory_path, :user_detail_path, :personal_access_token_revoke_path,
                :ssh_key_delete_path, :gpg_keys_available?

  before_action :check_license_credentials_inventory_available!, only: [:index, :revoke, :destroy]

  track_redis_hll_event :index, name: 'i_compliance_credential_inventory'

  feature_category :compliance_management

  private

  def check_license_credentials_inventory_available!
    render_404 unless credentials_inventory_feature_available?
  end

  override :credentials_inventory_path
  def credentials_inventory_path(args)
    admin_credentials_path(args)
  end

  override :filter_credentials
  def filter_credentials
    show_gpg_keys? ? ::GpgKeysFinder.new(users: users).execute : super
  end

  override :user_detail_path
  def user_detail_path(user)
    admin_user_path(user)
  end

  override :ssh_key_delete_path
  def ssh_key_delete_path(key)
    admin_credential_path(key)
  end

  override :personal_access_token_revoke_path
  def personal_access_token_revoke_path(token)
    revoke_admin_credential_path(token)
  end

  override :gpg_keys_available?
  def gpg_keys_available?
    true
  end

  override :users
  def users
    nil
  end

  override :revocable
  def revocable
    nil
  end
end
