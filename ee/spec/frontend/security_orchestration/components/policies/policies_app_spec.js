import { nextTick } from 'vue';
import PoliciesHeader from 'ee/security_orchestration/components/policies/policies_header.vue';
import PoliciesList from 'ee/security_orchestration/components/policies/policies_list.vue';
import PoliciesApp from 'ee/security_orchestration/components/policies/policies_app.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Policies App', () => {
  let wrapper;

  const findPoliciesHeader = () => wrapper.findComponent(PoliciesHeader);
  const findPoliciesList = () => wrapper.findComponent(PoliciesList);

  const createWrapper = () => {
    wrapper = shallowMountExtended(PoliciesApp, {});
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when does have an environment enabled', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('mounts the policies header component', () => {
      expect(findPoliciesHeader().exists()).toBe(true);
    });

    it.each`
      component         | findFn
      ${'PolicyHeader'} | ${findPoliciesHeader}
      ${'PolicyList'}   | ${findPoliciesList}
    `(
      'sets the `shouldUpdatePolicyList` variable from the $component component',
      async ({ findFn }) => {
        expect(findPoliciesList().props('shouldUpdatePolicyList')).toBe(false);
        findFn().vm.$emit('update-policy-list', true);
        await nextTick();
        expect(findPoliciesList().props('shouldUpdatePolicyList')).toBe(true);
      },
    );
  });
});
