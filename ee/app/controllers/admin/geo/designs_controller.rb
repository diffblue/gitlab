# frozen_string_literal: true

class Admin::Geo::DesignsController < Admin::Geo::ApplicationController
  before_action :check_license!
  before_action :load_node_data, only: [:index]
  before_action :warn_viewing_primary_replication_data, only: [:index]

  def index
    return unless Feature.enabled?(:geo_design_management_repository_replication)

    redirect_to admin_geo_nodes_path
  end
end
