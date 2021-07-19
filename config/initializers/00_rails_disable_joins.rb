# frozen_string_literal: true

module DisableJoins
  module ConfigurableDisableJoins
    extend ActiveSupport::Concern

    def disable_joins
      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      return @disable_joins.call if @disable_joins.is_a?(Proc)

      @disable_joins
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end

  module Association
    extend ActiveSupport::Concern

    attr_reader :disable_joins

    def initialize(owner, reflection)
      super

      @disable_joins = @reflection.options[:disable_joins] || false
    end

    def scope
      if disable_joins
        DisableJoinsAssociationScope.create.scope(self)
      else
        super
      end
    end

    def association_scope
      if klass
        @association_scope ||= begin # rubocop:disable Gitlab/ModuleWithInstanceVariables
          if disable_joins
            DisableJoinsAssociationScope.scope(self)
          else
            super
          end
        end
      end
    end
  end

  module HasOne
    extend ActiveSupport::Concern

    class_methods do
      def valid_options(options)
        valid = super
        valid += [:disable_joins] if options[:disable_joins] && options[:through]
        valid
      end
    end
  end

  module HasMany
    extend ActiveSupport::Concern

    class_methods do
      def valid_options(options)
        valid = super
        valid += [:disable_joins] if options[:disable_joins] && options[:through]
        valid
      end
    end
  end

  module HasOneThroughAssociation
    extend ActiveSupport::Concern

    def find_target
      return scope.first if disable_joins

      super
    end
  end

  module HasManyThroughAssociation
    extend ActiveSupport::Concern

    def find_target
      return [] unless target_reflection_has_associated_record?
      return scope.to_a if disable_joins

      super
    end
  end

  module PreloaderThroughAssociation
    extend ActiveSupport::Concern

    def through_scope
      scope = through_reflection.klass.unscoped
      options = reflection.options

      return scope if options[:disable_joins]

      super
    end
  end

  class DisableJoinsAssociationScope < ::ActiveRecord::Associations::AssociationScope # :nodoc:
    def scope(association)
      source_reflection = association.reflection
      owner = association.owner
      unscoped = association.klass.unscoped
      reverse_chain = get_chain(source_reflection, association, unscoped.alias_tracker).reverse

      last_reflection, last_ordered, last_join_ids = last_scope_chain(reverse_chain, owner)

      add_constraints(last_reflection, last_reflection.join_primary_key, last_join_ids, owner, last_ordered)
    end

    private

    def last_scope_chain(reverse_chain, owner)
      first_scope = [reverse_chain.shift, false, [owner.id]]

      reverse_chain.inject(first_scope) do |(reflection, ordered, join_ids), next_reflection|
        key = reflection.join_primary_key
        records = add_constraints(reflection, key, join_ids, owner, ordered)
        foreign_key = next_reflection.join_foreign_key
        record_ids = records.pluck(foreign_key)
        records_ordered = records && records.order_values.any?

        [next_reflection, records_ordered, record_ids]
      end
    end

    def add_constraints(reflection, key, join_ids, owner, ordered)
      scope = reflection.build_scope(reflection.aliased_table).where(key => join_ids)
      scope = reflection.constraints.inject(scope) do |memo, scope_chain_item|
        item = eval_scope(reflection, scope_chain_item, owner)
        scope.unscope!(*item.unscope_values)
        scope.where_clause += item.where_clause
        scope.order_values = item.order_values | scope.order_values
        scope
      end

      if scope.order_values.empty? && ordered
        split_scope = DisableJoinsAssociationRelation.create(scope.klass, key, join_ids)
        split_scope.where_clause += scope.where_clause
        split_scope
      else
        scope
      end
    end
  end

  module DelegateCache
    def relation_delegate_class(klass)
      @relation_delegate_cache2[klass] || super # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def initialize_relation_delegate_cache_disable_joins
      @relation_delegate_cache2 = {} # rubocop:disable Gitlab/ModuleWithInstanceVariables

      [
        DisableJoinsAssociationRelation
      ].each do |klass|
        delegate = Class.new(klass) do
          include ::ActiveRecord::Delegation::ClassSpecificRelation
        end
        include_relation_methods(delegate)
        mangled_name = klass.name.gsub("::", "_")
        const_set mangled_name, delegate
        private_constant mangled_name

        @relation_delegate_cache2[klass] = delegate # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end

    def inherited(child_class)
      child_class.initialize_relation_delegate_cache_disable_joins
      super
    end
  end

  class DisableJoinsAssociationRelation < ::ActiveRecord::Relation # :nodoc:
    attr_reader :ids, :key

    def initialize(klass, key, ids)
      @ids = ids.uniq
      @key = key
      super(klass)
    end

    def limit(value)
      records.take(value)
    end

    def first(limit = nil)
      if limit
        records.limit(limit).first
      else
        records.first
      end
    end

    def load
      super
      records = @records

      records_by_id = records.group_by do |record|
        record[key]
      end

      records = ids.flat_map { |id| records_by_id[id.to_i] }
      records.compact!

      @records = records
    end
  end
end

ActiveRecord::Associations::Association.prepend(DisableJoins::Association)
# Temporarily allow :disable_joins to accept a lambda argument, to control rollout with feature flags
ActiveRecord::Associations::Association.prepend(DisableJoins::ConfigurableDisableJoins)
ActiveRecord::Associations::Builder::HasOne.prepend(DisableJoins::HasOne)
ActiveRecord::Associations::Builder::HasMany.prepend(DisableJoins::HasMany)
ActiveRecord::Associations::HasOneThroughAssociation.prepend(DisableJoins::HasOneThroughAssociation)
ActiveRecord::Associations::HasManyThroughAssociation.prepend(DisableJoins::HasManyThroughAssociation)
ActiveRecord::Associations::Preloader::ThroughAssociation.prepend(DisableJoins::PreloaderThroughAssociation)
ActiveRecord::Base.extend(DisableJoins::DelegateCache)
