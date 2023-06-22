# frozen_string_literal: true

module Elastic
  module MultiVersionUtil
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    attr_reader :data_class, :data_target, :use_separate_indices

    # TODO: remove once multi-version is functional https://gitlab.com/gitlab-org/gitlab/issues/10156
    TARGET_VERSION = 'V12p1'

    # @params version [String, Module] can be a string "V12p1" or module (Elastic::V12p1)
    def version(version)
      version = Elastic.const_get(version, false) if version.is_a?(String)

      version.const_get(proxy_class_name, false).new(data_target, use_separate_indices: use_separate_indices)
    end

    # TODO: load from db table https://gitlab.com/gitlab-org/gitlab/issues/12555
    def elastic_reading_target
      strong_memoize(:elastic_reading_target) do
        version(TARGET_VERSION)
      end
    end

    # TODO: load from db table https://gitlab.com/gitlab-org/gitlab/issues/12555
    def elastic_writing_targets
      strong_memoize(:elastic_writing_targets) do
        [elastic_reading_target]
      end
    end

    private

    def get_data_class(klass)
      klass.try(:base_class) || klass
    end

    # Handles which method calls should be forwarded to all targets,
    # and which calls should be forwarded to just one target.
    #
    # This first sets up forwarding for methods which should go to all targets.
    # This is specified by implementing `methods_for_all_write_targets`.
    # Examples include document indexing/updating operations.
    #
    # Then other methods are forwarded to just the single read target.
    # Examples include user searches.
    #
    # Special write operations specified in `methods_for_one_write_target` are left out.
    # The caller must always specify the version the call should be triggered.
    # Examples include deleting the whole index.
    def generate_forwarding
      methods_for_all_write_targets = elastic_writing_targets.first.real_class.methods_for_all_write_targets
      methods_for_one_write_target = elastic_writing_targets.first.real_class.methods_for_one_write_target

      methods_for_all_write_targets.each do |method|
        self.class.forward_to_all_write_targets(method)
      end

      read_methods = elastic_reading_target.real_class.public_instance_methods
      read_methods -= methods_for_all_write_targets
      read_methods -= methods_for_one_write_target
      read_methods -= self.class.instance_methods
      read_methods.delete(:method_missing)

      read_methods.each do |method|
        self.class.forward_read_method(method)
      end
    end

    class_methods do
      def forward_read_method(method)
        return if respond_to?(method)

        delegate method, to: :elastic_reading_target
      end

      def forward_to_all_write_targets(method)
        return if respond_to?(method)

        define_method(method) do |*args|
          responses = elastic_writing_targets.map do |elastic_target|
            elastic_target.public_send(method, *args) # rubocop:disable GitlabSecurity/PublicSend
          end

          responses.find { |response| response['_shards']['successful'] == 0 } || responses.last
        end
      end
    end
  end
end
