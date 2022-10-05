# frozen_string_literal: true

module EE
  module Ci
    module RunnerPolicy
      extend ActiveSupport::Concern

      prepended do
        rule { auditor }.policy do
          enable :read_runner
        end
      end
    end
  end
end
