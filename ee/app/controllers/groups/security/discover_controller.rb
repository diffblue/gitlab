# frozen_string_literal: true

class Groups::Security::DiscoverController < Groups::ApplicationController
  layout 'group'

  feature_category :vulnerability_management
  urgency :low

  def show
    render_404 unless helpers.show_discover_group_security?(@group)
  end
end
