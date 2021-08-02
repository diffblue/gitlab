import PoliciesApp from 'ee/threat_monitoring/components/policies/policies_app.vue';
import PoliciesHeader from 'ee/threat_monitoring/components/policies/policies_header.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Policies App', () => {
  let wrapper;

  const findPoliciesHeader = () => wrapper.findComponent(PoliciesHeader);

  beforeEach(() => {
    wrapper = shallowMountExtended(PoliciesApp);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('mounts the policies header component', () => {
    expect(findPoliciesHeader().exists()).toBe(true);
  });
});
