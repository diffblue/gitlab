import { shallowMount } from '@vue/test-utils';
import PolicyEnvironments from 'ee/security_orchestration/components/policy_environments.vue';

describe('PolicyEnvironments component', () => {
  let wrapper;

  const createComponent = (nodes = []) => {
    wrapper = shallowMount(PolicyEnvironments, {
      propsData: {
        environments: { nodes },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it("renders the environement's name if there is only one", () => {
    const name = 'My environment';
    createComponent([{ name }]);

    expect(wrapper.text()).toBe(name);
  });

  it("renders the first environement's name and a count of the remaining ones", () => {
    const firstEnvironmentName = 'Primary environment';
    createComponent([
      { name: firstEnvironmentName },
      {
        name: 'Secondary environment',
      },
      {
        name: 'Tertiary environment',
      },
    ]);

    expect(wrapper.text()).toMatchInterpolatedText(`${firstEnvironmentName} +2 more`);
  });

  it('renders a "-" when there is no environment', () => {
    createComponent();

    expect(wrapper.text()).toBe('-');
  });
});
