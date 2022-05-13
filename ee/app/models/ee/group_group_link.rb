# frozen_string_literal: true

module EE
  module GroupGroupLink
    extend ActiveSupport::Concern

    prepended do
      scope :in_shared_group, -> (shared_groups) { where(shared_group: shared_groups) }
      scope :not_in_shared_with_group, -> (shared_with_groups) { where.not(shared_with_group: shared_with_groups) }
    end
  end
end
