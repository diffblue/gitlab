# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include IntegrationsActions
  include IntegrationsHelper

  before_action :not_found, unless: -> { instance_level_integrations? }

  feature_category :integrations

  def overrides
    respond_to do |format|
      format.json do
        projects = Project.with_active_integration(integration.class).merge(::Integration.not_inherited)
        serializer = ::Integrations::ProjectSerializer.new.with_pagination(request, response)

        render json: serializer.represent(projects)
      end
      # TODO frontend will add format.html
    end
  end

  private

  def find_or_initialize_non_project_specific_integration(name)
    Integration.find_or_initialize_non_project_specific_integration(name, instance: true)
  end
end
