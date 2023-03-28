# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::RevertToDetectedService, feature_category: :vulnerability_management do
  include AccessMatchersGeneric

  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:comment) { "wheee" }

  let(:project) { create(:project) } # cannot use let_it_be here: caching causes problems with permission-related tests
  let(:vulnerability) { create(:vulnerability, :with_findings, project: project) }
  let(:state_transition) { create(:vulnerability_state_transition, vulnerability: vulnerability) }
  let(:service) { described_class.new(user, vulnerability, comment) }

  subject(:revert_vulnerability_to_detected) { service.execute }

  shared_examples 'reverts vulnerability' do
    it 'reverts a vulnerability and its associated findings to detected state' do
      freeze_time do
        revert_vulnerability_to_detected

        expect(vulnerability.reload).to(
          have_attributes(state: 'detected', dismissed_by: nil, dismissed_at: nil, resolved_by: nil, resolved_at: nil, confirmed_by: nil, confirmed_at: nil))
      end
    end

    it 'creates note' do
      expect(SystemNoteService).to receive(:change_vulnerability_state).with(vulnerability, user)

      revert_vulnerability_to_detected
    end

    it 'creates state transition entry to `detected`' do
      expect(::Vulnerabilities::StateTransition).to receive(:create!).with(
        vulnerability: vulnerability,
        from_state: vulnerability.state,
        to_state: :detected,
        author: user,
        comment: comment
      )
      revert_vulnerability_to_detected
    end

    it_behaves_like 'calls vulnerability statistics utility services in order'
  end

  context 'with an authorized user with proper permissions' do
    before do
      project.add_developer(user)
    end

    context 'when vulnerability state is different from the requested state' do
      context 'when vulnerability is dismissed' do
        let(:vulnerability) { create(:vulnerability, :dismissed, :with_findings, project: project) }

        include_examples 'reverts vulnerability'

        it_behaves_like 'removes dismissal feedback from associated findings'

        context 'when feature flag deprecate_vulnerabilities_feedback is disabled' do
          before do
            stub_feature_flags(deprecate_vulnerabilities_feedback: false)
          end

          it_behaves_like 'removes dismissal feedback from associated findings'
        end
      end

      context 'when vulnerability is confirmed' do
        let(:vulnerability) { create(:vulnerability, :confirmed, :with_findings, project: project) }

        include_examples 'reverts vulnerability'

        it_behaves_like 'removes dismissal feedback from associated findings'
      end

      context 'when vulnerability is resolved' do
        let(:vulnerability) { create(:vulnerability, :resolved, :with_findings, project: project) }

        include_examples 'reverts vulnerability'

        it_behaves_like 'removes dismissal feedback from associated findings'
      end

      context 'when security dashboard feature is disabled' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it 'raises an "access denied" error' do
          expect { revert_vulnerability_to_detected }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end
  end

  context 'when vulnerability state is not different from the requested state' do
    let(:state) { :detected }
    let(:action) { revert_vulnerability_to_detected }

    it_behaves_like 'does not create state transition for same state'
  end

  describe 'permissions' do
    context 'when admin mode is enabled', :enable_admin_mode do
      it { expect { revert_vulnerability_to_detected }.to be_allowed_for(:admin) }
    end

    context 'when admin mode is disabled' do
      it { expect { revert_vulnerability_to_detected }.to be_denied_for(:admin) }
    end

    it { expect { revert_vulnerability_to_detected }.to be_allowed_for(:owner).of(project) }
    it { expect { revert_vulnerability_to_detected }.to be_allowed_for(:maintainer).of(project) }
    it { expect { revert_vulnerability_to_detected }.to be_allowed_for(:developer).of(project) }

    it { expect { revert_vulnerability_to_detected }.to be_denied_for(:auditor) }
    it { expect { revert_vulnerability_to_detected }.to be_denied_for(:reporter).of(project) }
    it { expect { revert_vulnerability_to_detected }.to be_denied_for(:guest).of(project) }
    it { expect { revert_vulnerability_to_detected }.to be_denied_for(:anonymous) }
  end
end
