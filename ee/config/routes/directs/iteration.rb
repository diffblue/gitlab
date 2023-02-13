# frozen_string_literal: true

# @!method iteration_path(iteration, options = {})
# @!method iteration_url(iteration, options = {})
direct(:iteration) do |iteration, *args|
  group_iteration_url(iteration.group, iteration.id, *args)
end
