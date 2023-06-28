# frozen_string_literal: true

class Vulnerabilities::FindingSerializer < BaseSerializer
  include WithPagination

  entity Vulnerabilities::FindingEntity

  def represent(resource, opts = {})
    if paginated?
      resource = paginator.paginate(resource)
    end

    super(resource, opts)
  end
end
