# frozen_string_literal: true

class ScimFinder
  include ::Gitlab::Utils::StrongMemoize

  attr_reader :group, :saml_provider

  UnsupportedFilter = Class.new(StandardError)

  def initialize(group = nil)
    raise ArgumentError, 'Group cannot be nil' if group.nil? && ::Gitlab.com?

    @group = group
  end

  def search(params)
    return null_identity unless saml_enabled?
    return all_identities if unfiltered?(params)

    filter_identities(params)
  end

  private

  def null_identity
    ScimIdentity.none
  end

  def saml_enabled?
    return Gitlab::Auth::Saml::Config.enabled? unless group
    return false unless group.saml_provider

    group.saml_provider.enabled?
  end

  def all_identities
    return group.scim_identities if group

    ScimIdentity.all
  end

  def unfiltered?(params)
    params[:filter].blank?
  end

  def filter_identities(params)
    parser = EE::Gitlab::Scim::ParamsParser.new(params)

    if eq_filter_on_extern_uid?(parser)
      by_extern_uid(parser.filter_params[:extern_uid])
    elsif eq_filter_on_username?(parser)
      identity = by_extern_uid(parser.filter_params[:username])
      return identity if identity.present?

      by_username(parser.filter_params[:username])
    else
      raise UnsupportedFilter
    end
  end

  def eq_filter_on_extern_uid?(parser)
    parser.filter_operator == :eq && parser.filter_params[:extern_uid].present?
  end

  def by_extern_uid(extern_uid)
    return group.scim_identities.with_extern_uid(extern_uid) if group

    ScimIdentity.with_extern_uid(extern_uid)
  end

  def eq_filter_on_username?(parser)
    parser.filter_operator == :eq && parser.filter_params[:username].present?
  end

  def by_username(username)
    user = User.find_by_username(username)

    if !user && email?(username)
      user ||= User.find_by_any_email(username) || User.find_by_username(email_local_part(username))
    end

    return group.scim_identities.for_user(user) if group

    ScimIdentity.for_user(user)
  end

  def email?(email)
    ::ValidateEmail.valid?(email)
  end

  def email_local_part(email)
    ::Mail::Address.new(email).local
  end
end
