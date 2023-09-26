# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :real_ai_request) do |example|
    real_ai_request_bool = ActiveModel::Type::Boolean.new.cast(ENV['REAL_AI_REQUEST'])
    open_ai_embeddings_bool = ActiveModel::Type::Boolean.new.cast(ENV['OPENAI_EMBEDDINGS'])
    vertex_ai_embeddings_bool = ActiveModel::Type::Boolean.new.cast(ENV['VERTEX_AI_EMBEDDINGS'])

    if !real_ai_request_bool || !ENV['ANTHROPIC_API_KEY'] || !(open_ai_embeddings_bool ^ vertex_ai_embeddings_bool)
      puts "skipping '#{example.description}' because it does real third-party requests, set " \
           "REAL_AI_REQUEST=true and ANTHROPIC_API_KEY='<key>' and only one of OPENAI_EMBEDDINGS=true " \
           "or VERTEX_AI_EMBEDDINGS=true if you really want to run the test"
      next
    end

    if open_ai_embeddings_bool && !ENV['OPENAI_API_KEY']
      puts "skipping '#{example.description}' because you picked to run spec examples with OPENAI_EMBEDDINGS=true, " \
           "set the OPENAI_API_KEY=<key>"
      next
    end

    if vertex_ai_embeddings_bool && !ENV['VERTEX_CREDENTIALS'] && !ENV['VERTEX_AI_PROJECT']
      puts "skipping '#{example.description}' because you picked to run spec examples VERTEX_AI_EMBEDDINGS=true " \
           "set the VERTEX_AI_CREDENTIALS=<credentials-json> and VERTEX_AI_PROJECT=<project-id>"
      next
    end

    with_net_connect_allowed do
      original_value = Feature.enabled?(:use_embeddings_with_vertex)
      Feature.enable(:use_embeddings_with_vertex) if vertex_ai_embeddings_bool
      Feature.disable(:use_embeddings_with_vertex) if open_ai_embeddings_bool

      example.run

      original_value ? Feature.enable(:use_embeddings_with_vertex) : Feature.disable(:use_embeddings_with_vertex)
    end
  end

  config.before(:each, :real_ai_request) do
    allow(Gitlab::CurrentSettings.current_application_settings).to receive(:anthropic_api_key)
      .at_least(:once).and_return(ENV['ANTHROPIC_API_KEY'])
    allow(Gitlab::CurrentSettings.current_application_settings).to receive(:openai_api_key)
      .at_least(:once).and_return(ENV['OPENAI_API_KEY'])
    allow(Gitlab::CurrentSettings.current_application_settings).to receive(:vertex_ai_credentials)
      .at_least(:once).and_return(ENV['VERTEX_AI_CREDENTIALS'])
    allow(Gitlab::CurrentSettings.current_application_settings).to receive(:vertex_ai_project)
      .at_least(:once).and_return(ENV['VERTEX_AI_PROJECT'])
  end

  config.before(:context, :ai_embedding_fixtures) do
    add_openai_embeddings_from_fixture unless ::Embedding::TanukiBotMvc.any?
    add_vertex_embeddings_from_fixture unless ::Embedding::Vertex::GitlabDocumentation.any?
  end

  def add_openai_embeddings_from_fixture
    fixture_path = Rails.root.join("ee/spec/fixtures/openai_embeddings")
    embedding_model = ::Embedding::TanukiBotMvc
    copy_from_statement = "COPY #{embedding_model.table_name} FROM '#{fixture_path}'"

    embedding_model.connection.execute(copy_from_statement)

    embedding_model.set_current_version!(embedding_model.last.version)
  end

  def add_vertex_embeddings_from_fixture
    fixture_path = Rails.root.join("ee/spec/fixtures/vertex_embeddings")
    embedding_model = ::Embedding::Vertex::GitlabDocumentation
    copy_from_statement = "COPY #{embedding_model.table_name} FROM '#{fixture_path}'"

    embedding_model.connection.execute(copy_from_statement)
  end
end
