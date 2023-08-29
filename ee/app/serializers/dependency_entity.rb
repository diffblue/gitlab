# frozen_string_literal: true

class DependencyEntity < Grape::Entity
  include RequestAwareEntity

  class AncestorEntity < Grape::Entity
    expose :name, :version
  end

  class LocationEntity < Grape::Entity
    expose :blob_path, :path, :top_level
    expose :ancestors, using: AncestorEntity
  end

  class VulnerabilityEntity < Grape::Entity
    expose :name, :severity, :id, :url
  end

  class LicenseEntity < Grape::Entity
    expose :name, :url

    def name
      object[:name] || object["name"]
    end

    def url
      object[:url] || object["url"]
    end
  end

  class ProjectEntity < Grape::Entity
    expose :full_path, :name
  end

  expose :name, :packager, :version
  expose :location, using: LocationEntity
  expose :vulnerabilities, using: VulnerabilityEntity, if: ->(_) { can_read_vulnerabilities? }
  expose :licenses, using: LicenseEntity, if: ->(_) { can_read_licenses? }
  expose :project, using: ProjectEntity, if: ->(_) { group? }
  expose :project_count, :occurrence_count, if: ->(_) { group_counts? }
  expose :component_id, if: ->(_) { group? }

  private

  def can_read_vulnerabilities?
    can?(request.user, :read_security_resource, request.project)
  end

  def can_read_licenses?
    (group? && Feature.enabled?(:group_level_licenses, group)) ||
      can?(request.user, :read_licenses, request.project)
  end

  def group
    request.respond_to?(:group) ? request.group : nil
  end

  def group?
    group.present?
  end

  def group_counts?
    group? &&
      object.respond_to?(:project_count) &&
      object.respond_to?(:occurrence_count)
  end
end
