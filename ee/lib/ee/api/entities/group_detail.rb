# frozen_string_literal: true

module EE
  module API
    module Entities
      module GroupDetail
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit
          expose :extra_shared_runners_minutes_limit
          expose :prevent_forking_outside_group?,
                 as: :prevent_forking_outside_group
          expose :membership_lock?,
                 as: :membership_lock
        end
      end
    end
  end
end
