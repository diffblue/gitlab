# frozen_string_literal: true
class Groups::Security::ComplianceDashboardsController < Groups::ApplicationController
  include Groups::SecurityFeaturesHelper
  include RedisTracking

  layout 'group'

  before_action :authorize_compliance_dashboard!

  track_redis_hll_event :show, name: 'g_compliance_dashboard'

  feature_category :compliance_management

  def show; end
end
