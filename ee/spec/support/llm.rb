# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :real_ai_request) do |example|
    unless ENV['REAL_AI_REQUEST'] && ENV['ANTHROPIC_API_KEY']
      puts "skipping '#{example.description}' because it does real third-party requests, set " \
           "REAL_AI_REQUEST=true and ANTHROPIC_API_KEY='<key>' environment variables if you really want to run the test"
      next
    end

    example.run
  end

  config.before(:each, :real_ai_request) do
    WebMock.allow_net_connect!
    allow(Gitlab::CurrentSettings.current_application_settings).to receive(:anthropic_api_key)
      .at_least(:once).and_return(ENV['ANTHROPIC_API_KEY'])
  end
end
