# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Operations routing', 'routing' do
  describe '/-/operations' do
    it 'routes to the operations index action' do
      expect(get("#{operations_path}.html")).to route_to(
        controller: 'operations',
        action: 'index',
        format: 'html')

      expect(get("#{operations_path}.json")).to route_to(
        controller: 'operations',
        action: 'index',
        format: 'json')
    end

    it 'routes to the operations create action' do
      expect(post("#{add_operations_project_path}.json")).to route_to(
        controller: 'operations',
        action: 'create',
        format: 'json')
    end

    it 'routes to operations destroy action' do
      expect(delete("#{remove_operations_project_path}.json")).to route_to(
        controller: 'operations',
        action: 'destroy',
        format: 'json')
    end
  end

  describe '/-/operations/environments' do
    it 'routes to the environments list action' do
      expect(get("#{operations_environments_path}.html")).to route_to(
        controller: 'operations',
        action: 'environments',
        format: 'html')

      expect(get("#{operations_environments_path}.json")).to route_to(
        controller: 'operations',
        action: 'environments',
        format: 'json')
    end

    it 'routes to the environments create action' do
      expect(post("#{add_operations_environments_project_path}.json")).to route_to(
        controller: 'operations',
        action: 'create',
        format: 'json')
    end

    it 'routes to environments destroy action' do
      expect(delete("#{remove_operations_environments_project_path}.json")).to route_to(
        controller: 'operations',
        action: 'destroy',
        format: 'json')
    end
  end
end
