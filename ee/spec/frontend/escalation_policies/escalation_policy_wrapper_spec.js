import { GlEmptyState, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import EscalationPoliciesWrapper from 'ee/escalation_policies/components/escalation_policies_wrapper.vue';
import EscalationPolicy from 'ee/escalation_policies/components/escalation_policy.vue';
import AddEscalationPolicyModal from 'ee/escalation_policies/components/add_edit_escalation_policy_modal.vue';
import { parsePolicy } from 'ee/escalation_policies/utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import mockEscalationPolicies from './mocks/mockPolicies.json';

describe('Escalation Policies Wrapper', () => {
  let wrapper;
  const emptyEscalationPoliciesSvgPath = 'illustration/path.svg';
  const projectPath = 'group/project';

  function mountComponent({ loading = false, escalationPolicies = [] } = {}) {
    const $apollo = {
      queries: {
        escalationPolicies: {
          loading,
        },
      },
    };
    wrapper = shallowMountExtended(EscalationPoliciesWrapper, {
      provide: {
        emptyEscalationPoliciesSvgPath,
        projectPath,
      },
      mocks: {
        $apollo,
      },
      data() {
        return {
          escalationPolicies,
        };
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findLoader = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findEscalationPolicies = () => wrapper.findAllComponents(EscalationPolicy);
  const findEscalationPolicyModal = () => wrapper.findComponent(AddEscalationPolicyModal);
  const findAlert = () => wrapper.findComponent(GlAlert);

  describe.each`
    state             | loading  | escalationPolicies        | showsEmptyState | showsLoader
    ${'is loading'}   | ${true}  | ${[]}                     | ${false}        | ${true}
    ${'is empty'}     | ${false} | ${[]}                     | ${true}         | ${false}
    ${'has policies'} | ${false} | ${mockEscalationPolicies} | ${false}        | ${false}
  `(`When $state`, ({ loading, escalationPolicies, showsEmptyState, showsLoader }) => {
    beforeEach(() => {
      mountComponent({
        loading,
        escalationPolicies: escalationPolicies.map(parsePolicy),
      });
    });

    it(`does ${loading ? 'show' : 'not show'} a loader`, () => {
      expect(findLoader().exists()).toBe(showsLoader);
    });

    it(`does ${showsEmptyState ? 'show' : 'not show'} an empty state`, () => {
      expect(findEmptyState().exists()).toBe(showsEmptyState);
    });

    it(`does ${escalationPolicies.length ? 'show' : 'not show'} escalation policies`, () => {
      expect(findEscalationPolicies()).toHaveLength(escalationPolicies.length);
    });
  });

  describe('Escalation policy created alert', () => {
    it('should display alert when when policy created', async () => {
      mountComponent({
        loading: false,
        escalationPolicies: mockEscalationPolicies.map(parsePolicy),
      });
      expect(findAlert().exists()).toBe(false);

      findEscalationPolicyModal().vm.$emit('policy-created');
      await nextTick();
      expect(findAlert().exists()).toBe(true);

      findAlert().vm.$emit('dismiss');
      await nextTick();
      expect(findAlert().exists()).toBe(false);
    });
  });
});
