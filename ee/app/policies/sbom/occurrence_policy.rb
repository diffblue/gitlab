# frozen_string_literal: true

module Sbom
  class OccurrencePolicy < BasePolicy
    delegate { @subject.project }
  end
end
