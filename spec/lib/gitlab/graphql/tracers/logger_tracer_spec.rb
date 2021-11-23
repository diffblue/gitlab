# frozen_string_literal: true
require "spec_helper"

RSpec.describe Gitlab::Graphql::Tracers::LoggerTracer do
  let(:dummy_schema) do
    Class.new(GraphQL::Schema) do
      # LoggerTracer depends on TimerTracer
      use Gitlab::Graphql::Tracers::LoggerTracer
      use Gitlab::Graphql::Tracers::TimerTracer

      query_analyzer Gitlab::Graphql::QueryAnalyzers::AST::LoggerAnalyzer

      query Graphql::FakeQueryType
    end
  end

  around do |example|
    Gitlab::ApplicationContext.with_context(caller_id: 'caller_a', feature_category: 'feature_a') do
      example.run
    end
  end

  it "logs every query", :aggregate_failures do
    variables = { name: "Ada Lovelace" }
    query_string = 'query fooOperation($name: String) { helloWorld(message: $name) }'

    # Build an actual query so we don't have to hardcode the "fingerprint" calculations
    query = GraphQL::Query.new(dummy_schema, query_string, variables: variables)

    expect(::Gitlab::GraphqlLogger).to receive(:info).with({
      trace_type: "execute_query",
      query_fingerprint: query.fingerprint,
      duration_s: be > 0,
      operation_name: 'fooOperation',
      operation_fingerprint: query.operation_fingerprint,
      is_mutation: false,
      variables: variables.to_s,
      query_string: query_string,
      "correlation_id" => anything,
      "meta.caller_id" => "caller_a",
      "meta.feature_category" => "feature_a",
      "query_analysis.query_string" => query_string,
      "query_analysis.variables" => variables.to_s,
      "query_analysis.duration_s" => kind_of(Numeric),
      "query_analysis.operation_name" => 'fooOperation',
      "query_analysis.depth" => 1,
      "query_analysis.complexity" => 1,
      "query_analysis.used_fields" => ["FakeQuery.helloWorld"],
      "query_analysis.used_deprecated_fields" => []
    })

    dummy_schema.execute(query_string, variables: variables)
  end

  it 'logs exceptions for breaking queries' do
    query_string = "query fooOperation { breakingField }"

    expect(::Gitlab::GraphqlLogger).to receive(:info).with(a_hash_including({
      'exception.message' => 'This field is supposed to break',
      'exception.class' => 'RuntimeError'
    }))

    expect { dummy_schema.execute(query_string) }.to raise_error(/This field is supposed to break/)
  end
end
