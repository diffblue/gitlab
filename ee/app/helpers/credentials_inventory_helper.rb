# frozen_string_literal: true

module CredentialsInventoryHelper
  VALID_FILTERS = %w(ssh_keys personal_access_tokens gpg_keys resource_access_tokens).freeze

  def show_personal_access_tokens?
    return true if params[:filter] == 'personal_access_tokens'

    VALID_FILTERS.exclude? params[:filter]
  end

  def show_ssh_keys?
    params[:filter] == 'ssh_keys'
  end

  def show_gpg_keys?
    params[:filter] == 'gpg_keys'
  end

  def show_resource_access_tokens?
    params[:filter] == 'resource_access_tokens'
  end

  def credentials_inventory_feature_available?
    License.feature_available?(:credentials_inventory)
  end

  def gpg_keys_available?
    false
  end

  def credentials_inventory_path(args)
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def ssh_key_delete_path(key)
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def user_detail_path(user)
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end

  def personal_access_token_revoke_path(token)
    raise NotImplementedError, "#{self.class} does not implement #{__method__}"
  end
end
