# frozen_string_literal: true

class Admin::Geo::SettingsController < Admin::ApplicationSettingsController
  helper ::EE::GeoHelper
  before_action :check_license!, except: :show

  feature_category :geo_replication
  urgency :low

  def show
  end

  protected

  def check_license!
    unless Gitlab::Geo.license_allows?
      render_403
    end
  end
end
