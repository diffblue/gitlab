# frozen_string_literal: true

RSpec.shared_examples 'deletes all standalone indices' do
  Gitlab::Elastic::Helper::ES_SEPARATE_CLASSES.each do |class_name|
    describe class_name do
      it 'removes a standalone index' do
        proxy = ::Elastic::Latest::ApplicationClassProxy.new(class_name, use_separate_indices: true)

        expect { subject }.to change { helper.index_exists?(index_name: proxy.index_name) }.from(true).to(false)
      end
    end
  end
end
