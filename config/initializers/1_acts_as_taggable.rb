# frozen_string_literal: true

ActsAsTaggableOn.strict_case_match = true

# tags_counter enables caching count of tags which results in an update whenever a tag is added or removed
# since the count is not used anywhere its better performance wise to disable this cache
ActsAsTaggableOn.tags_counter = false

# validate that counter cache is disabled
raise "Counter cache is not disabled" if
    ActsAsTaggableOn::Tagging.reflections["tag"].options[:counter_cache]

# Redirects retrieve_connection to use Ci::ApplicationRecord's connection
[::ActsAsTaggableOn::Tag, ::ActsAsTaggableOn::Tagging].each do |model|
  model.connection_specification_name = Ci::ApplicationRecord.connection_specification_name
  model.singleton_class.delegate :connection, :sticking, to: '::Ci::ApplicationRecord'
end

# Can be removed once https://github.com/mbleigh/acts-as-taggable-on/pull/1081
# is merged
module ActsAsTaggableOnTagPatch
  def find_or_create_all_with_like_by_name(*list)
    list = Array(list).flatten

    return [] if list.empty?

    existing_tags = named_any(list)
    list.map do |tag_name|
      tries ||= 3
      comparable_tag_name = comparable_name(tag_name)
      existing_tag = existing_tags.find { |tag| comparable_name(tag.name) == comparable_tag_name }
      next existing_tag if existing_tag

      transaction(requires_new: true) { create(name: tag_name) }
    rescue ActiveRecord::RecordNotUnique
      if (tries -= 1).positive? # rubocop:disable Style/NumericPredicate
        existing_tags = named_any(list)
        retry
      end

      raise ::ActsAsTaggableOn::DuplicateTagError, "'#{tag_name}' has already been taken"
    end
  end
end

::ActsAsTaggableOn::Tag.singleton_class.prepend(ActsAsTaggableOnTagPatch)
