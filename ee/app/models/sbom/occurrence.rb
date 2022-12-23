# frozen_string_literal: true

module Sbom
  class Occurrence < ApplicationRecord
    include EachBatch

    belongs_to :component, optional: false
    belongs_to :component_version
    belongs_to :project, optional: false
    belongs_to :pipeline, class_name: 'Ci::Pipeline'
    belongs_to :source

    validates :commit_sha, presence: true
    validates :uuid, presence: true, uniqueness: { case_sensitive: false }
  end
end
