# frozen_string_literal: true

RSpec.shared_examples 'update only allow merge if all status checks passed' do
  context 'when only_allow_merge_if_all_status_checks_passed param is specified' do
    before do
      stub_licensed_features(external_status_checks: true)
    end

    it 'updates the attribute' do
      request

      expect(project.reload.only_allow_merge_if_all_status_checks_passed).to be_truthy
    end

    context 'when license is not sufficient' do
      before do
        stub_licensed_features(external_status_checks: false)
      end

      it 'does not update the attribute' do
        request

        expect(project.reload.only_allow_merge_if_all_status_checks_passed).to be_falsy
      end
    end
  end
end
