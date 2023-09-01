# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class EpicAiEntity < EpicEntity
  expose :epic_comments do |_epic, options|
    options[:resource].notes_with_limit(options[:user], notes_limit: options[:notes_limit])
  end
end
# rubocop: enable Gitlab/NamespacedClass
