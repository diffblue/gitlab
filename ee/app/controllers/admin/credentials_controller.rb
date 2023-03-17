# frozen_string_literal: true

class Admin::CredentialsController < Admin::ApplicationController
  extend ::Gitlab::Utils::Override
  include CredentialsInventoryActions
  include ProductAnalyticsTracking

  helper_method :credentials_inventory_path, :user_detail_path, :personal_access_token_revoke_path,
    :ssh_key_delete_path, :gpg_keys_available?

  before_action :check_license_credentials_inventory_available!, only: [:index, :revoke, :destroy]

  track_event :index,
    name: 'i_compliance_credential_inventory',
    action: 'visit_compliance_credential_inventory',
    label: 'redis_hll_counters.compliance.compliance_total_unique_counts_monthly',
    destinations: [:redis_hll, :snowplow]

  feature_category :compliance_management

  private

  def tracking_namespace_source
    nil
  end

  def tracking_project_source
    nil
  end

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
