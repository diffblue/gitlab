# frozen_string_literal: true

module RemoteDevelopment
  # noinspection RubyClassModuleNamingConvention, RubyInstanceMethodNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
  # noinspection RubyInstanceMethodNamingConvention - See https://handbook.gitlab.com/handbook/tools-and-tips/editors-and-ides/jetbrains-ides/code-inspection/why-are-there-noinspection-comments/
  module RailwayOrientedProgrammingHelpers
    # NOTE: Depends upon `initial_value` being defined in the including spec
    def stub_methods_to_return_ok_result(*methods)
      methods.each do |method|
        allow(method).to receive(:call).with(initial_value) { Result.ok(initial_value) }
      end
    end

    # NOTE: Depends upon `initial_value` and `err_message_context` being defined in the including spec
    def stub_methods_to_return_err_result(method:, message_class:)
      allow(method).to receive(:call).with(initial_value) do
        # noinspection RubyResolve
        Result.err(message_class.new(err_message_context))
      end
    end

    def stub_methods_to_return_value(*methods)
      methods.each do |method|
        allow(method).to receive(:call).with(initial_value) { initial_value }
      end
    end
  end
end
