import { nextTick } from 'vue';
import PoliciesHeader from 'ee/security_orchestration/components/policies/policies_header.vue';
import PoliciesList from 'ee/security_orchestration/components/policies/policies_list.vue';
import PoliciesApp from 'ee/security_orchestration/components/policies/policies_app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Policies App', () => {
  let wrapper;

  const findPoliciesHeader = () => wrapper.findComponent(PoliciesHeader);
  const findPoliciesList = () => wrapper.findComponent(PoliciesList);

  const createWrapper = (assignedPolicyProject = null) => {
    wrapper = shallowMountExtended(PoliciesApp, { provide: { assignedPolicyProject } });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the policies list correctly', () => {
      expect(findPoliciesList().props('shouldUpdatePolicyList')).toBe(false);
      expect(findPoliciesList().props('hasPolicyProject')).toBe(false);
    });

    it.each`
      component         | emitFn                | emitData                                                    | finalPropStates
      ${'PolicyHeader'} | ${findPoliciesHeader} | ${{ shouldUpdatePolicyList: true, hasPolicyProject: true }} | ${true}
      ${'PolicyList'}   | ${findPoliciesList}   | ${{ shouldUpdatePolicyList: false }}                        | ${false}
    `(
      'updates the policy list when a change is made from the $component component',
      async ({ emitFn, emitData, finalPropStates }) => {
        expect(findPoliciesList().props('shouldUpdatePolicyList')).toBe(false);
        expect(findPoliciesList().props('hasPolicyProject')).toBe(false);
        emitFn().vm.$emit('update-policy-list', emitData);
        await nextTick();
        expect(findPoliciesList().props('shouldUpdatePolicyList')).toBe(finalPropStates);
        expect(findPoliciesList().props('hasPolicyProject')).toBe(finalPropStates);
      },
    );
  });

  it('renders correctly when a policy project is linked', async () => {
    createWrapper({ id: '1' });
    await nextTick();

    expect(findPoliciesList().props('hasPolicyProject')).toBe(true);
  });
});
