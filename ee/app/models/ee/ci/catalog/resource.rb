# frozen_string_literal: true

module EE
  module Ci
    module Catalog
      module Resource
        extend ActiveSupport::Concern

        prepended do
          after_commit on: [:create, :destroy] do
            project.maintain_elasticsearch_update if project.maintaining_elasticsearch?
          end
        end
      end
    end
  end
end
