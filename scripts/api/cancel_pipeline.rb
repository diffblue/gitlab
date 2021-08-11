#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'gitlab'
require 'optparse'
require_relative 'get_job_id'

class CancelPipeline
  DEFAULT_OPTIONS = {
    project: ENV['CI_PROJECT_ID'],
    pipeline_id: ENV['CI_PIPELINE_ID'],
    # Default to "CI scripts API usage" at https://gitlab.com/gitlab-org/gitlab/-/settings/access_tokens
    api_token: ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE']
  }.freeze

  def initialize(options)
    @project = options.delete(:project)
    @pipeline_id = options.delete(:pipeline_id)

    @client = Gitlab.client(
      endpoint: ENV.fetch('CI_API_V4_URL', 'https://gitlab.com/api/v4'),
      private_token: options.delete(:api_token)
    )
  end

  def execute
    client.cancel_pipeline(project, pipeline_id)
  end

  private

  attr_reader :project, :pipeline_id, :client
end

if $0 == __FILE__
  options = CancelPipeline::DEFAULT_OPTIONS.dup

  OptionParser.new do |opts|
    opts.on("-p", "--project PROJECT", String, "Project where to find the job (defaults to $CI_PROJECT_ID)") do |value|
      options[:project] = value
    end

    opts.on("-i", "--pipeline-id PIPELINE_ID", String, "A pipeline ID (defaults to $CI_PIPELINE_ID)") do |value|
      options[:pipeline_id] = value
    end

    opts.on("-t", "--api-token API_TOKEN", String, "A value API token with the `read_api` scope") do |value|
      options[:api_token] = value
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!

  CancelPipeline.new(options).execute
end
