# frozen_string_literal: true

class Groups::WikisController < Groups::ApplicationController
  include WikiActions

  urgency :low

  alias_method :container, :group

  feature_category :wiki

  private

  def authorize_read_wiki!
    access_denied! unless can?(current_user, :read_wiki, group)
  end

  def authorize_create_wiki!
    access_denied! unless can?(current_user, :create_wiki, group)
  end

  def authorize_admin_wiki!
    access_denied! unless can?(current_user, :admin_wiki, group)
  end
end
