# frozen_string_literal: true

class ElasticQueryNameInspector
  attr_reader :names

  def initialize
    @names = Set.new
  end

  def inspect(query)
    query.extend(Hashie::Extensions::DeepFind)
    @names += query.deep_find_all("_name")
  end

  def has_named_query?(*expected_names)
    @names.superset?(expected_names.to_set)
  end

  def excludes_named_query?(*unexpected_names)
    unexpected_names.all? { |name| @names.exclude?(name) }
  end
end
