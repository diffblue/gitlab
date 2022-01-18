# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        module Group
          class Base
            attr_reader :group, :options

            def initialize(group:, options:)
              @group = group
              @options = options
            end

            def identifier
              self.class.name.demodulize.underscore.to_sym
            end

            def title
              raise NotImplementedError, "Expected #{self.name} to implement title"
            end

            def value
              raise NotImplementedError, "Expected #{self.name} to implement value"
            end

            def links
              []
            end
          end
        end
      end
    end
  end
end
