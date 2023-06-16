# frozen_string_literal: true

FILENAME = "ee/lib/tasks/gitlab/llm/questions.csv"

namespace :gitlab do
  namespace :llm do
    namespace :zero_shot do
      namespace :test do
        # to run this using own issue example, please use syntax below:
        # rake "gitlab:llm:zero_shot:test:questions[<issue_url>]"
        # please note usage of quotes to pass argument
        # if run without quotes and argument, it will use predefined issue
        desc 'Synchronously run predefined AI questions'
        task :questions, [:issue] => [:environment] do |_t, args|
          args.with_defaults(issue: 'http://127.0.0.1:3001/jashkenas/Underscore/-/issues/41')

          zero_shot_prompt_action = "the action to take, should be one from this list"

          ::CSV.read(FILENAME).each do |row|
            next if row[0].blank?

            question = format(row[0], { issue_identifier: args.issue })
            logger.info("question: #{question}")
            logger.info("expected tool(s): #{row[1]}")

            agent = llm_agent({ content: question, sync: true })
            response = agent.execute

            actions = agent.prompt.scan(/Action: (?<action>.+?)(?=$)/)
            actions.reject! { |action| action.first.start_with?(zero_shot_prompt_action) }

            logger.info("tools used: #{actions}")
            logger.info("actual response: #{response.content}")
            logger.info("\n\n")
          end
        end
      end

      def logger
        @logger ||= Logger.new($stdout)
      end

      def llm_agent(options)
        tools = [
          ::Gitlab::Llm::Chain::Tools::ExplainCode,
          ::Gitlab::Llm::Chain::Tools::IssueIdentifier,
          ::Gitlab::Llm::Chain::Tools::JsonReader,
          ::Gitlab::Llm::Chain::Tools::SummarizeComments,
          ::Gitlab::Llm::Chain::Tools::GitlabDocumentation
        ]

        user = User.first
        resource = user
        ai_request = ::Gitlab::Llm::Chain::Requests::Anthropic.new(user)
        context = ::Gitlab::Llm::Chain::GitlabContext.new(
          current_user: user,
          container: resource.try(:resource_parent)&.root_ancestor,
          resource: resource,
          ai_request: ai_request
        )

        Gitlab::Llm::Chain::Agents::ZeroShot::Executor.new(
          user_input: options[:content],
          tools: tools,
          context: context
        )
      end
    end
  end
end
