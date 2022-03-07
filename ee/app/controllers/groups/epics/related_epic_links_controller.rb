# frozen_string_literal: true

# This controller is used for relating an epic with other epic (similar to
# issue links).  Note that this relation is different from existing
# EpicLinksController (which is used for parent-child epic hierarchy).
class Groups::Epics::RelatedEpicLinksController < Groups::ApplicationController
  include EpicRelations

  before_action :ensure_related_epics_enabled!
  before_action :check_epics_available!
  before_action :check_related_epics_available!

  feature_category :portfolio_management
  urgency :default

  private

  def list_service
    Epics::RelatedEpicLinks::ListService.new(epic, current_user)
  end

  def ensure_related_epics_enabled!
    render_404 unless Feature.enabled?(:related_epics_widget, epic&.group, default_enabled: :yaml)
  end
end
