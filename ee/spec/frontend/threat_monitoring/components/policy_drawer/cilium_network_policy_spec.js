import { GlIntersperse } from '@gitlab/ui';
import CiliumNetworkPolicy from 'ee/threat_monitoring/components/policy_drawer/cilium_network_policy.vue';
import { toYaml } from 'ee/threat_monitoring/components/policy_editor/network_policy/lib';
import PolicyPreviewHuman from 'ee/threat_monitoring/components/policy_editor/policy_preview_human.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('CiliumNetworkPolicy component', () => {
  let wrapper;
  const supportedYaml = toYaml({
    name: 'test-policy',
    description: 'test description',
    endpointLabels: '',
    rules: [],
  });
  const unsupportedYaml = 'unsupportedPrimaryKey: test';

  const findPolicyPreview = () => wrapper.findComponent(PolicyPreviewHuman);
  const findDescription = () => wrapper.findByTestId('description');
  const findEnvironments = () => wrapper.findByTestId('environments');

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(CiliumNetworkPolicy, {
      propsData: {
        ...propsData,
      },
      stubs: {
        GlIntersperse,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('supported YAML', () => {
    beforeEach(() => {
      factory({ propsData: { policy: { yaml: supportedYaml } } });
    });

    it('renders policy preview', () => {
      expect(wrapper.find('div').element).toMatchSnapshot();
    });

    it('does render the policy description', () => {
      expect(findDescription().exists()).toBe(true);
      expect(findDescription().text()).toContain('test description');
    });

    it('does render the policy preview', () => {
      expect(findPolicyPreview().props('policyDescription')).toBe('Deny all traffic');
    });
  });

  describe('unsupported YAML', () => {
    beforeEach(() => {
      factory({ propsData: { policy: { yaml: unsupportedYaml } } });
    });

    it('renders policy preview', () => {
      expect(wrapper.find('div').element).toMatchSnapshot();
    });

    it('does not render the policy description', () => {
      expect(findDescription().exists()).toBe(false);
    });

    it('does render the policy preview', () => {
      expect(findPolicyPreview().exists()).toBe(true);
      expect(findPolicyPreview().props('policyDescription')).toBe(null);
    });
  });

  describe('environments', () => {
    it('renders environments if any', () => {
      factory({
        propsData: {
          policy: {
            environments: {
              nodes: [{ name: 'production' }, { name: 'local' }],
            },
            yaml: supportedYaml,
          },
        },
      });
      expect(findEnvironments().exists()).toBe(true);
      expect(findEnvironments().text()).toContain('production');
      expect(findEnvironments().text()).toContain('local');
    });

    it("does not render environments row if there aren't any", () => {
      factory({
        propsData: {
          policy: {
            environments: {
              nodes: [],
            },
            yaml: supportedYaml,
          },
        },
      });
      expect(findEnvironments().exists()).toBe(false);
    });
  });
});
