# frozen_string_literal: true

module MergeRequests
  module Llm
    class SummarizeMergeRequestService
      GIT_DIFF_PREFIX_REGEX = /\A@@( -\d+,\d+ \+\d+,\d+ )@@/

      def initialize(merge_request:, user:)
        @merge_request = merge_request
        @user = user
      end

      def execute
        return unless enabled? && @user.can?(:read_merge_request, @merge_request) && llm_client

        response = llm_client.chat(content: summary_message)

        return unless response.respond_to?(:parsed_response)
        return unless response.parsed_response.fetch("choices", nil)

        response.parsed_response["choices"].first.dig("message", "content")
      end

      def enabled?
        Feature.enabled?(:openai_experimentation, @user) &&
          @merge_request.project.experiment_features_enabled? &&
          @merge_request.project.third_party_ai_features_enabled? &&
          @merge_request.send_to_ai?
      end

      private

      def prompt
        "The above is the code diff of a merge request. The merge request's " \
          "title is: '#{@merge_request.title}'\n\n" \
          "Write a summary the way an expert engineer would summarize the " \
          "changes using simple - generally non-technical - terms."
      end

      def summary_message
        # Truncate diffs_blob to 2000 "words" which roughly translates to
        #   ~1500 tokens according to OpenAI guidance.
        #
        extracted_diff.truncate_words(2000) << prompt
      end

      def extracted_diff
        # Extract only the diff strings and discard everything else
        #
        diffs = @merge_request.raw_diffs.to_a.collect(&:diff)

        # Each diff string starts with information about the lines changed,
        #   bracketed by @@. Removing this saves us tokens.
        #
        # Ex: @@ -0,0 +1,58 @@\n+# frozen_string_literal: true\n+\n+module MergeRequests\n+
        #
        diffs.map { |diff| diff.sub(GIT_DIFF_PREFIX_REGEX, "") }.join
      end

      def llm_client
        @_llm_client ||= Gitlab::Llm::OpenAi::Client.new(@user)
      end
    end
  end
end
