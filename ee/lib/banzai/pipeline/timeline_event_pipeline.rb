# frozen_string_literal: true

module Banzai
  module Pipeline
    class TimelineEventPipeline < BasePipeline
      ALLOWLIST = Banzai::Filter::SanitizationFilter::LIMITED.deep_dup.merge(
        elements: %w(p b i strong em pre code a img)
      )

      def self.filters
        @filters ||= FilterArray[
          Filter::MarkdownFilter,
          Filter::EmojiFilter,
          Filter::ExternalLinkFilter,
          Filter::ImageLinkFilter,
          Filter::SanitizationFilter,
          *reference_filters
        ]
      end

      def self.reference_filters
        [
          Filter::References::UserReferenceFilter,
          Filter::References::IssueReferenceFilter,
          Filter::References::ExternalIssueReferenceFilter,
          Filter::References::MergeRequestReferenceFilter,
          Filter::References::SnippetReferenceFilter,
          Filter::References::CommitRangeReferenceFilter,
          Filter::References::CommitReferenceFilter,
          Filter::References::AlertReferenceFilter,
          Filter::References::FeatureFlagReferenceFilter
        ]
      end

      def self.transform_context(context)
        Filter::AssetProxyFilter.transform_context(context).merge(
          only_path: true,
          no_sourcepos: true,
          allowlist: ALLOWLIST,
          link_replaces_image: true
        )
      end
    end
  end
end
