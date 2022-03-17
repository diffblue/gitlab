# frozen_string_literal: true

class Admin::Geo::DesignsController < Admin::Geo::ApplicationController
  before_action :check_license!
  before_action :load_node_data, only: [:index]
  before_action :warn_viewing_primary_replication_data, only: [:index]

  def index
  end
end
