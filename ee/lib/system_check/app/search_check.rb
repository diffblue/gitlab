# frozen_string_literal: true

module SystemCheck
  module App
    class SearchCheck < SystemCheck::BaseCheck
      set_name 'Elasticsearch version 7.x-8.x or OpenSearch version 1.x'
      set_skip_reason 'skipped (Advanced Search is disabled)'
      set_check_pass -> { "yes (#{self.distribution} #{self.current_version})" }
      set_check_fail -> { "no (#{self.distribution} #{self.current_version})" }

      def self.info
        @info ||= Gitlab::Elastic::Helper.default.server_info
      end

      def self.distribution
        info[:distribution]
      end

      def self.current_version
        Gitlab::VersionInfo.parse(info[:version])
      end

      def skip?
        !Gitlab::CurrentSettings.current_application_settings.elasticsearch_indexing?
      end

      def check?
        valid_elasticsearch_version? || valid_opensearch_version?
      end

      def show_error
        for_more_information(
          'doc/integration/advanced_search/elasticsearch.md'
        )
      end

      private

      def valid_elasticsearch_version?
        elasticsearch? && current_version.major.in?([7, 8])
      end

      def valid_opensearch_version?
        opensearch? && current_version.major >= 1
      end

      def current_version
        self.class.current_version
      end

      def elasticsearch?
        self.class.distribution == 'elasticsearch'
      end

      def opensearch?
        self.class.distribution == 'opensearch'
      end
    end
  end
end
