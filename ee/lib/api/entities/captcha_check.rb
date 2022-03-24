# frozen_string_literal: true

module API
  module Entities
    class CaptchaCheck < Grape::Entity
      expose :result
    end
  end
end
