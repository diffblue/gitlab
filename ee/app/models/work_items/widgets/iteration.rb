# frozen_string_literal: true

module WorkItems
  module Widgets
    class Iteration < Base
      delegate :iteration, to: :work_item
    end
  end
end
