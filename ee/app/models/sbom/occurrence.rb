# frozen_string_literal: true

module Sbom
  class Occurrence < ApplicationRecord
    belongs_to :component_version, optional: false
    belongs_to :project, optional: false
    belongs_to :pipeline, class_name: 'Ci::Pipeline'
    belongs_to :source

    validates :commit_sha, presence: true
  end
end
