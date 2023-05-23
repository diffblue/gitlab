# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class Answer
        attr_accessor :status, :content, :context, :tool, :suggestions, :is_final
        alias_method :is_final?, :is_final

        def initialize(status:, context:, content:, tool:, suggestions: nil, is_final: false)
          @status = status
          @context = context
          @content = content
          @tool = tool
          @suggestions = suggestions
          @is_final = is_final
        end

        def self.from_response(response_body:, tools:, context:)
          parser = Parsers::ChainOfThoughtParser.new(output: response_body)
          parser.parse

          return final_answer(context: context, content: response_body) if parser.final_answer

          action = parser.action
          action_input = parser.action_input
          thought = parser.thought

          tool = tools.find { |tool| tool.name == action }

          return final_answer(context: context, content: default_final_answer) unless tool

          new(
            status: :ok,
            context: context,
            content: action_input,
            tool: tool,
            suggestions: thought,
            is_final: false
          )
        end

        def self.final_answer(context:, content:)
          new(
            status: :ok,
            context: context,
            content: content,
            tool: nil,
            suggestions: nil,
            is_final: true
          )
        end

        def self.default_final_answer
          _("AI|I don't see how I can help. Please give better instructions!")
        end
      end
    end
  end
end
