# frozen_string_literal: true

module Projects
  class TargetBranchRule < ApplicationRecord
    include StripAttribute

    belongs_to :project, inverse_of: :target_branch_rules

    validates :project, presence: true
    validates :name, presence: true, uniqueness: { scope: :project_id },
      format: { with: %r{\A(?!.*\.\./)[a-zA-Z0-9/._\-*]+\z} }
    validates :target_branch, presence: true, length: { maximum: 255 }

    strip_attributes! :name

    def name=(name)
      super(name.try(:downcase))
    end
  end
end
