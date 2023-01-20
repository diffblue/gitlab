# frozen_string_literal: true

module Dast
  class ProfileTag < ApplicationRecord
    self.table_name = 'dast_profiles_tags'

    belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag', optional: false
    belongs_to :dast_profile, class_name: 'Dast::Profile', optional: false
  end
end
