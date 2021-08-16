import NoEnvironmentEmptyState from 'ee/threat_monitoring/components/no_environment_empty_state.vue';
import PoliciesApp from 'ee/threat_monitoring/components/policies/policies_app.vue';
import PoliciesHeader from 'ee/threat_monitoring/components/policies/policies_header.vue';
import PoliciesList from 'ee/threat_monitoring/components/policies/policies_list.vue';
import createStore from 'ee/threat_monitoring/store';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Policies App', () => {
  let wrapper;
  let store;
  let setCurrentEnvironmentIdSpy;
  let fetchEnvironmentsSpy;

  const findPoliciesHeader = () => wrapper.findComponent(PoliciesHeader);
  const findPoliciesList = () => wrapper.findComponent(PoliciesList);
  const findEmptyState = () => wrapper.findComponent(NoEnvironmentEmptyState);

  const createWrapper = ({ provide } = {}) => {
    store = createStore();

    setCurrentEnvironmentIdSpy = jest
      .spyOn(PoliciesApp.methods, 'setCurrentEnvironmentId')
      .mockImplementation(() => {});

    fetchEnvironmentsSpy = jest
      .spyOn(PoliciesApp.methods, 'fetchEnvironments')
      .mockImplementation(() => {});

    wrapper = shallowMountExtended(PoliciesApp, {
      store,
      provide: {
        defaultEnvironmentId: -1,
        ...provide,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when does have an environment enabled', () => {
    beforeEach(() => {
      createWrapper({ provide: { defaultEnvironmentId: 22 } });
    });

    it('mounts the policies header component', () => {
      expect(findPoliciesHeader().exists()).toBe(true);
    });

    it('mounts the policies list component', () => {
      expect(findPoliciesList().exists()).toBe(true);
    });

    it('does not mount the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('fetches the environments when created', async () => {
      expect(setCurrentEnvironmentIdSpy).toHaveBeenCalled();
      expect(fetchEnvironmentsSpy).toHaveBeenCalled();
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
        await wrapper.vm.$nextTick();
        expect(findPoliciesList().props('shouldUpdatePolicyList')).toBe(true);
      },
    );
  });

  describe('when does not have an environment enabled', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('mounts the policies header component', () => {
      expect(findPoliciesHeader().exists()).toBe(true);
    });

    it('does not mount the policies list component', () => {
      expect(findPoliciesList().exists()).toBe(false);
    });

    it('mounts the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('does not fetch the environments when created', () => {
      expect(setCurrentEnvironmentIdSpy).not.toHaveBeenCalled();
      expect(fetchEnvironmentsSpy).not.toHaveBeenCalled();
    });
  });
});
