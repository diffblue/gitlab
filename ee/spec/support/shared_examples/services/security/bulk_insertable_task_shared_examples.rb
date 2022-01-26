# frozen_string_literal: true

RSpec.shared_examples 'bulk insertable task' do
  context 'when the validation fails' do
    let(:proxy_class_instance) { described_class.klass.new }

    before do
      proxy_class_instance.errors.add(:attribute, 'is invalid')
    end

    it 'can generate error messages correctly' do
      expect(proxy_class_instance.errors.full_messages).to contain_exactly 'Attribute is invalid'
    end
  end
end
