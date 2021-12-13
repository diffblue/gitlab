# frozen_string_literal: true

class Geo::PagesDeploymentRegistry < Geo::BaseRegistry
  include ::Geo::ReplicableRegistry
  include ::Geo::VerifiableRegistry

  MODEL_CLASS = ::PagesDeployment
  MODEL_FOREIGN_KEY = :pages_deployment_id

  belongs_to :pages_deployment, class_name: 'PagesDeployment'
end
