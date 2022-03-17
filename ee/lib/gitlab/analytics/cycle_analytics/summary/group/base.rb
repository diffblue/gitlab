# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        module Group
          class Base
            include Gitlab::CycleAnalytics::Summary::Defaults

            attr_reader :group, :options

            def initialize(group:, options:)
              @group = group
              @options = options
            end
          end
        end
      end
    end
  end
end
