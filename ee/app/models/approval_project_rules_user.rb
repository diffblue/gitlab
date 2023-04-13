# frozen_string_literal: true

# Model for join table between ApprovalProjectRule and User
# create to enable exports ApprovalProjectRule
class ApprovalProjectRulesUser < ApplicationRecord # rubocop:disable Gitlab/NamespacedClass
  belongs_to :user
  belongs_to :approval_project_rule, class_name: 'ApprovalProjectRule'
end
