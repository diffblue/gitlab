# frozen_string_literal: true

class ScimOauthAccessTokenEntity < Grape::Entity
  include ::API::Helpers::RelatedResourcesHelpers

  GROUP_SCIM_PATH = '/api/scim/v2/groups'
  INSTANCE_SCIM_PATH = '/api/scim/v2/application'

  expose :scim_api_url do |scim|
    if scim.group
      expose_url("#{GROUP_SCIM_PATH}/#{scim.group.full_path}")
    else
      expose_url(INSTANCE_SCIM_PATH)
    end
  end

  expose :token, as: :scim_token
end
