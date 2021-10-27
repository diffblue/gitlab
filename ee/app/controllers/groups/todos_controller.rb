# frozen_string_literal: true

class Groups::TodosController < Groups::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include TodosActions

  before_action :authenticate_user!, only: [:create]

  feature_category :portfolio_management

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def issuable
    strong_memoize(:epic) do
      next if params[:issuable_type] != 'epic'

      EpicsFinder.new(current_user, group_id: @group.id).find(params[:issuable_id])
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
