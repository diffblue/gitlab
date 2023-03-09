import { GlEmptyState, GlLoadingIcon, GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import EscalationPoliciesWrapper, {
  i18n,
} from 'ee/escalation_policies/components/escalation_policies_wrapper.vue';
import EscalationPolicy from 'ee/escalation_policies/components/escalation_policy.vue';
import AddEscalationPolicyModal from 'ee/escalation_policies/components/add_edit_escalation_policy_modal.vue';
import { parsePolicy } from 'ee/escalation_policies/utils';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import mockEscalationPolicies from './mocks/mockPolicies.json';

describe('Escalation Policies Wrapper', () => {
  let wrapper;
  const emptyEscalationPoliciesSvgPath = 'illustration/path.svg';
  const projectPath = 'group/project';
  const accessLevelDescriptionPath = 'group/project/-/project_members?sort=access_level_desc';

  function mountComponent({
    loading = false,
    escalationPolicies = [],
    userCanCreateEscalationPolicy = true,
    isShallowExtendedMount = true,
  } = {}) {
    const $apollo = {
      queries: {
        escalationPolicies: {
          loading,
        },
      },
    };

    const mountProps = {
      provide: {
        emptyEscalationPoliciesSvgPath,
        projectPath,
        userCanCreateEscalationPolicy,
        accessLevelDescriptionPath,
      },
      mocks: {
        $apollo,
      },
      stubs: {
        GlSprintf,
      },
      data() {
        return {
          escalationPolicies,
        };
      },
    };

    wrapper = isShallowExtendedMount
      ? shallowMountExtended(EscalationPoliciesWrapper, mountProps)
      : mountExtended(EscalationPoliciesWrapper, mountProps);
  }

  beforeEach(() => {
    mountComponent();
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

  describe('Escalation policy empty state', () => {
    it('should allow to create policy when user is at least a maintainer', () => {
      mountComponent({ isShallowExtendedMount: false });

      expect(findEmptyState().props('title')).toBe(i18n.emptyState.title);
      expect(wrapper.findByText(i18n.emptyState.description).exists()).toBe(true);
      expect(wrapper.findByRole('button', { name: i18n.emptyState.button }).exists()).toBe(true);
    });

    it('should show message about role restrictions when user is below maintainer level', () => {
      mountComponent({ userCanCreateEscalationPolicy: false, isShallowExtendedMount: false });

      expect(findEmptyState().props('title')).toBe(i18n.emptyState.title);
      expect(wrapper.findComponent(GlLink).exists()).toBe(true);
      expect(wrapper.findByRole('button', { name: i18n.emptyState.button }).exists()).toBe(false);
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
