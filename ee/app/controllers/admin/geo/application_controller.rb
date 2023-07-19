# frozen_string_literal: true

class Admin::Geo::ApplicationController < Admin::ApplicationController
  helper ::EE::GeoHelper

  feature_category :geo_replication
  urgency :low

  protected

  def check_license!
    unless Gitlab::Geo.license_allows?
      render_403
    end
  end

  def load_node_data
    # used in replication controllers (replicables, projects, designs) and the
    # navbar data, to figure out which site's data we're trying to access
    @current_node = ::Gitlab::Geo.current_node
    @target_node = if params[:id]
                     GeoNode.find(params[:id])
                   else
                     ::Gitlab::Geo.current_node
                   end
  end
end
