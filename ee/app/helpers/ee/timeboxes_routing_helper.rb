# frozen_string_literal: true

module EE
  module TimeboxesRoutingHelper
    def iteration_path(iteration, *args)
      group_iteration_path(iteration.group, iteration.id, *args)
    end

    def iteration_url(iteration, *args)
      group_iteration_url(iteration.group, iteration.id, *args)
    end
  end
end
