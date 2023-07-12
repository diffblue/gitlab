# frozen_string_literal: true

module EE
  module Types
    module Ci
      module RunnerSortEnum
        extend ActiveSupport::Concern

        prepended do
          value 'MOST_ACTIVE_DESC',
            'Ordered by number of running jobs in descending order (only available on Ultimate plans).',
            value: :most_active_desc,
            alpha: { milestone: '16.2' }
        end
      end
    end
  end
end
