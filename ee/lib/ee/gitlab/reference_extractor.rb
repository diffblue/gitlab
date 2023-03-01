# frozen_string_literal: true

module EE
  module Gitlab
    module ReferenceExtractor
      extend ActiveSupport::Concern

      EE_REFERABLES = %i[iteration].freeze

      prepended do
        EE_REFERABLES.each do |type|
          define_method(type.to_s.pluralize) do
            @references[type] ||= references(type)
          end
        end

        @referrables = referrables + EE_REFERABLES
      end
    end
  end
end
