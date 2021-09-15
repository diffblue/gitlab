# frozen_string_literal: true

module Elastic
  module AwardEmojisSearch
    extend ActiveSupport::Concern

    UPDATE_ELASTIC_ASSOCIATIONS_FOR = [::MergeRequest].freeze

    included do
      if self < ActiveRecord::Base
        after_commit :update_elastic_associations, on: [:create, :destroy]
      end
    end

    private

    def update_elastic_associations
      return unless UPDATE_ELASTIC_ASSOCIATIONS_FOR.any? { |model| awardable.is_a?(model) }
      return unless awardable.maintaining_elasticsearch?

      awardable.maintain_elasticsearch_update
    end
  end
end
