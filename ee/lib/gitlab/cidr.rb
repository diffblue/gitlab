# frozen_string_literal: true
require 'ipaddr'

module Gitlab
  class CIDR
    ValidationError = Class.new(StandardError)

    attr_reader :cidrs

    delegate :empty?, to: :cidrs

    def initialize(values)
      @cidrs = parse_cidrs(values)
    end

    def match?(ip)
      cidrs.find { |cidr| cidr.include?(ip) }.present?
    end

    private

    def parse_cidrs(values)
      values.to_s.split(',').map do |value|
        ::IPAddr.new(value.strip)
      end
    rescue StandardError => e
      raise ValidationError, e.message
    end
  end
end
