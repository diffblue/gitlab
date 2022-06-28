# frozen_string_literal: true
module LicenseCompliance
  class CollapsedComparerEntity < Grape::Entity
    include RequestAwareEntity

    expose :new_licenses do |comparer|
      comparer.new_licenses.count
    end

    expose :existing_licenses do |comparer|
      comparer.existing_licenses.count
    end

    expose :removed_licenses do |comparer|
      comparer.removed_licenses.count
    end

    expose :approval_required do |_|
      request.approval_required
    end

    expose :has_denied_licenses do |_|
      request.has_denied_licenses
    end
  end
end
