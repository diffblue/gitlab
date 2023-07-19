# frozen_string_literal: true

FILENAME = "ee/lib/tasks/gitlab/llm/questions.yml"

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
          require 'yaml'

          args.with_defaults(issue: 'http://127.0.0.1:3001/jashkenas/Underscore/-/issues/41')

          zero_shot_prompt_action = "the action to take, should be one from this list"
          counter = 0.0
          correct_answers_counter = 0
          default_answers_counter = 0
          reset_chat

          YAML.load_file(FILENAME).values.flatten.each do |row|
            counter += 1
            question = format(row['question'], { issue_identifier: args.issue })
            logger.info("question: #{question}")
            logger.info("expected tool(s): #{row['answer']}")

            agent = llm_agent({ content: question, sync: true })
            response = agent.execute

            actions = agent.prompt[:prompt].scan(/Action: (?<action>.+?)(?=$)/)
            actions.reject! { |action| action.first.start_with?(zero_shot_prompt_action) }

            correct_answers_counter += accuracy_check(actions, row['answer'], response.content)
            default_answers_counter += default_answer_check(response.content) ? 1 : 0

            logger.info("tools used: #{actions}")
            logger.info("actual response: #{response.content}")
            logger.info("current accuracy rate #{(correct_answers_counter / counter) * 100}%")
            logger.info("current default answer counter #{default_answers_counter}")
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

        resource = current_user
        ai_request = ::Gitlab::Llm::Chain::Requests::Anthropic.new(current_user)
        context = ::Gitlab::Llm::Chain::GitlabContext.new(
          current_user: current_user,
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

      def accuracy_check(actions, tools, final_answer)
        return 0 if default_answer_check(final_answer)

        actions = actions.flatten
        final_rating = 0

        if actions == tools
          final_rating += 1
        elsif actions.uniq == tools
          final_rating += tools.size.to_f / actions.size
        end

        final_rating
      end

      def default_answer_check(final_answer)
        final_answer == Gitlab::Llm::Chain::Answer.default_final_message
      end

      def current_user
        @current_user ||= User.first
      end

      def reset_chat
        messages = Gitlab::Llm::Cache.new(current_user).last_conversation
        return if messages.empty?

        Gitlab::Llm::Cache.new(current_user)
          .add({ request_id: SecureRandom.uuid, role: 'user', content: Gitlab::Llm::CachedMessage::RESET_MESSAGE })
      end
    end
  end
end
