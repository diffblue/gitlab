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

  def warn_viewing_primary_replication_data
    if ::Gitlab::Geo.primary?
      help_url = help_page_url('administration/geo/index', anchor: 'view-replication-data-on-the-primary-site')
      flash[:alert] = _('Viewing projects and designs data from a primary site is not possible when using a unified URL. Visit the secondary site directly. %{geo_help_url}').html_safe % {
        geo_help_url: view_context.link_to(_('Learn more.'), help_url, target: '_blank', rel: 'noopener noreferrer')
      }
    end
  end
end
