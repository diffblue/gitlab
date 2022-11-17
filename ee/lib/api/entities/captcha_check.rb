# frozen_string_literal: true

module API
  module Entities
    class CaptchaCheck < Grape::Entity
      expose :result, documentation: { type: 'boolean' }
    end
  end
end
