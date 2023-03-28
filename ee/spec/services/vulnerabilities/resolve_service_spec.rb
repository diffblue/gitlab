# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ResolveService, feature_category: :vulnerability_management do
  include AccessMatchersGeneric

  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:user) { create(:user) }
  let(:comment) { "resolve vulnerability comment" }

  let(:project) { create(:project) } # cannot use let_it_be here: caching causes problems with permission-related tests
  let(:vulnerability) { create(:vulnerability, project: project) }
  let(:state_transition) { create(:vulnerability_state_transition, vulnerability: vulnerability) }
  let(:last_state_transition) { vulnerability.state_transitions.last }
  let(:service) { described_class.new(user, vulnerability, comment) }

  subject(:resolve_vulnerability) { service.execute }

  context 'when vulnerability state is different from the requested state' do
    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'calls vulnerability statistics utility services in order'

      it_behaves_like 'removes dismissal feedback from associated findings'

      it 'resolves a vulnerability' do
        freeze_time do
          resolve_vulnerability

          expect(vulnerability.reload).to(
            have_attributes(state: 'resolved', resolved_by: user, resolved_at: be_like_time(Time.current)))
        end
      end

      it 'creates note' do
        expect(SystemNoteService).to receive(:change_vulnerability_state).with(vulnerability, user)

        resolve_vulnerability
      end

      it 'creates state transition entry to `resolved`' do
        expect(::Vulnerabilities::StateTransition).to receive(:create!).with(
          vulnerability: vulnerability,
          from_state: vulnerability.state,
          to_state: :resolved,
          author: user,
          comment: "resolve vulnerability comment"
        )

        resolve_vulnerability
      end

      context 'when security dashboard feature is disabled' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it 'raises an "access denied" error' do
          expect { resolve_vulnerability }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end
  end

  context 'when vulnerability state is not different from the requested state' do
    let(:state) { :resolved }
    let(:action) { resolve_vulnerability }

    it_behaves_like 'does not create state transition for same state'
  end

  describe 'permissions' do
    context 'when admin mode is enabled', :enable_admin_mode do
      it { expect { resolve_vulnerability }.to be_allowed_for(:admin) }
    end

    context 'when admin mode is disabled' do
      it { expect { resolve_vulnerability }.to be_denied_for(:admin) }
    end

    it { expect { resolve_vulnerability }.to be_allowed_for(:owner).of(project) }
    it { expect { resolve_vulnerability }.to be_allowed_for(:maintainer).of(project) }
    it { expect { resolve_vulnerability }.to be_allowed_for(:developer).of(project) }

    it { expect { resolve_vulnerability }.to be_denied_for(:auditor) }
    it { expect { resolve_vulnerability }.to be_denied_for(:reporter).of(project) }
    it { expect { resolve_vulnerability }.to be_denied_for(:guest).of(project) }
    it { expect { resolve_vulnerability }.to be_denied_for(:anonymous) }
  end
end
