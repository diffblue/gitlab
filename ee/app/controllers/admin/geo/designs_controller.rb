# frozen_string_literal: true

class Admin::Geo::DesignsController < Admin::Geo::ApplicationController
  before_action :check_license!
  before_action :load_node_data, only: [:index]

  def index
    return unless Feature.enabled?(:geo_design_management_repository_replication)

    redirect_to admin_geo_nodes_path unless @current_node
    redirect_to design_management_repositories_path
  end

  def design_management_repositories_path
    "/admin/geo/sites/#{@current_node.id}/replication/design_management_repositories"
  end
end
