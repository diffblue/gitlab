# frozen_string_literal: true
module LicenseCompliance
  class CollapsedComparerEntity < Grape::Entity
    expose :new_licenses do |comparer|
      comparer.new_licenses.count
    end

    expose :existing_licenses do |comparer|
      comparer.existing_licenses.count
    end

    expose :removed_licenses do |comparer|
      comparer.removed_licenses.count
    end
  end
end
