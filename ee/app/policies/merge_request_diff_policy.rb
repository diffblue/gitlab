# frozen_string_literal: true

# rubocop:disable Gitlab/NamespacedClass
# Cop is disabled because model is still named `MergeRequestDiff`.
class MergeRequestDiffPolicy < BasePolicy
  delegate { @subject.project }
end
# rubocop:enable Gitlab/NamespacedClass
