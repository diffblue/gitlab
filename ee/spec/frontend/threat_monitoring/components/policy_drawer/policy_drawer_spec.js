import { GlButton, GlDrawer, GlTabs, GlTab } from '@gitlab/ui';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/threat_monitoring/components/constants';
import CiliumNetworkPolicy from 'ee/threat_monitoring/components/policy_drawer/cilium_network_policy.vue';
import PolicyDrawer from 'ee/threat_monitoring/components/policy_drawer/policy_drawer.vue';
import ScanExecutionPolicy from 'ee/threat_monitoring/components/policy_drawer/scan_execution_policy.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockNetworkPoliciesResponse,
  mockCiliumPolicy,
  mockScanExecutionPolicy,
} from '../../mocks/mock_data';

const [mockGenericPolicy] = mockNetworkPoliciesResponse;

describe('PolicyDrawer component', () => {
  let wrapper;

  const factory = ({ mountFn = shallowMountExtended, propsData, stubs = {} } = {}) => {
    wrapper = mountFn(PolicyDrawer, {
      propsData: {
        editPolicyPath: '/policies/policy/edit?environment_id=-1',
        open: true,
        ...propsData,
      },
      stubs: { PolicyYamlEditor: true, ...stubs },
    });
  };

  // Finders
  const findEditButton = () => wrapper.findByTestId('edit-button');
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findCiliumNetworkPolicy = () => wrapper.findComponent(CiliumNetworkPolicy);
  const findScanExecutionPolicy = () => wrapper.findComponent(ScanExecutionPolicy);
  const findDefaultComponentPolicyEditor = () =>
    wrapper.findByTestId('policy-yaml-editor-default-component');
  const findTabPolicyEditor = () => wrapper.findByTestId('policy-yaml-editor-tab-content');

  // Shared assertions
  const itRendersEditButton = () => {
    it('renders edit button', () => {
      const button = findEditButton();
      expect(button.exists()).toBe(true);
      expect(button.attributes().href).toBe('/policies/policy/edit?environment_id=-1');
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('by default', () => {
    beforeEach(() => {
      factory({ stubs: { GlDrawer } });
    });

    it('does not render edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('given a generic network policy', () => {
    beforeEach(() => {
      factory({
        mountFn: mountExtended,
        propsData: {
          policy: mockGenericPolicy,
        },
      });
    });

    it('renders network policy editor with manifest', () => {
      expect(findDefaultComponentPolicyEditor().attributes('value')).toBe(mockGenericPolicy.yaml);
    });

    itRendersEditButton();
  });

  describe.each`
    policyType                                           | mock                       | finder
    ${POLICY_TYPE_COMPONENT_OPTIONS.container.value}     | ${mockCiliumPolicy}        | ${findCiliumNetworkPolicy}
    ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value} | ${mockScanExecutionPolicy} | ${findScanExecutionPolicy}
  `('given a $policyType policy', ({ policyType, mock, finder }) => {
    beforeEach(() => {
      factory({
        propsData: {
          policy: mock,
          policyType,
        },
        stubs: {
          GlButton,
          GlDrawer,
          GlTabs,
        },
      });
    });

    it(`renders the ${policyType} component`, () => {
      expect(finder().exists()).toBe(true);
    });

    it('renders the tabs', () => {
      expect(findAllTabs()).toHaveLength(2);
    });

    it('renders the policy editor', () => {
      expect(findTabPolicyEditor().attributes('value')).toBe(mock.yaml);
    });

    itRendersEditButton();
  });
});
