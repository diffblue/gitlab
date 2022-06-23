# frozen_string_literal: true

module EE
  module Clusters
    module Agent
      extend ActiveSupport::Concern

      prepended do
        scope :for_projects, -> (projects) { where(project: projects) }
      end
    end
  end
end
