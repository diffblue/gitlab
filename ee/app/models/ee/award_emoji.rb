# frozen_string_literal: true

module EE
  module AwardEmoji
    extend ActiveSupport::Concern

    prepended do
      include Elastic::AwardEmojisSearch
    end
  end
end
