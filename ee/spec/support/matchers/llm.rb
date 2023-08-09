# frozen_string_literal: true

RSpec::Matchers.define :match_llm_tools do |expected_tools|
  match do |prompt|
    zero_shot_prompt_actions = ['the action to take', 'DirectAnswer']
    actions = prompt[:prompt].scan(/Action: (?<action>.+?)(?=$)/)
    actions.reject! { |action| action.first.start_with?(*zero_shot_prompt_actions) }
    @tools = actions.flatten

    expected_tools == @tools
  end

  failure_message do
    <<~STR
      expected tools: #{tools}
                 got: #{@tools}
    STR
  end
end

RSpec::Matchers.define :match_llm_answer do |answer_regexp|
  match do |answer|
    answer&.match(answer_regexp)
  end

  failure_message do |answer|
    "expected a string matching #{answer_regexp} regexp, got '#{answer}'"
  end
end
