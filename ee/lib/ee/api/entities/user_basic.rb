# frozen_string_literal: true

module EE
  module API
    module Entities
      module UserBasic
        extend ActiveSupport::Concern

        prepended do
          expose :email, if: -> (user, options) { user.managed_by?(options[:current_user]) }
        end
      end
    end
  end
end
