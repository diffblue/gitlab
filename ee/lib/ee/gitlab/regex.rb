# frozen_string_literal: true

module EE
  module Gitlab
    module Regex
      extend ActiveSupport::Concern

      class_methods do
        def epic
          @epic ||= /(?<epic>\d+)(?<format>\+s{,1})?/
        end
      end
    end
  end
end
