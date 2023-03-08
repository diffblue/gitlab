# frozen_string_literal: true

RSpec.describe QA::EE::Resource::GroupBase do
  let(:klass) do
    Class.new do
      prepend QA::EE::Resource::GroupBase # rubocop:disable Cop/InjectEnterpriseEditionModule

      attr_reader :remove_calls

      def initialize(with_sandbox: true)
        @remove_calls = []

        return unless with_sandbox

        define_singleton_method :sandbox do
          true
        end
      end

      def reload!
        struct = Struct.new(:api_response)
        if remove_calls.size >= 1
          struct.new({ marked_for_deletion_on: true })
        else
          struct.new({})
        end
      end

      def api_delete_path
        '/foobar'
      end

      def full_path
        '/hello/foobar'
      end

      def remove_via_api!
        @remove_calls << api_delete_path
      end
    end
  end

  it 'requests deletion twice with immediate_remove_via_api!' do
    group = klass.new
    group.immediate_remove_via_api!
    expected = %w[/foobar /foobar?permanently_remove=true&full_path=%2Fhello%2Ffoobar]
    expect(group.remove_calls).to eql(expected)
  end

  it 'throws when trying to immediately remove a top level group' do
    group = klass.new(with_sandbox: false)
    expect { group.immediate_remove_via_api! }.to raise_error('Cannot immediately delete top level groups')
  end
end
