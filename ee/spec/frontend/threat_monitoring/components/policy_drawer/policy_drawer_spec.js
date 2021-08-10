import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/threat_monitoring/components/constants';
import CiliumNetworkPolicy from 'ee/threat_monitoring/components/policy_drawer/cilium_network_policy.vue';
import PolicyDrawer from 'ee/threat_monitoring/components/policy_drawer/policy_drawer.vue';
import ScanExecutionPolicy from 'ee/threat_monitoring/components/policy_drawer/scan_execution_policy.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockNetworkPoliciesResponse,
  mockCiliumPolicy,
  mockScanExecutionPolicy,
} from '../../mocks/mock_data';

const [mockGenericPolicy] = mockNetworkPoliciesResponse;

describe('PolicyDrawer component', () => {
  let wrapper;

  const factory = ({ propsData } = {}) => {
    wrapper = mountExtended(PolicyDrawer, {
      propsData: {
        editPolicyPath: '/policies/policy/edit?environment_id=-1',
        open: true,
        ...propsData,
      },
      stubs: { PolicyYamlEditor: true },
    });
  };

  // Finders
  const findEditButton = () => wrapper.findByTestId('edit-button');
  const findPolicyEditor = () => wrapper.findByTestId('policy-yaml-editor');
  const findCiliumNetworkPolicy = () => wrapper.findComponent(CiliumNetworkPolicy);
  const findScanExecutionPolicy = () => wrapper.findComponent(ScanExecutionPolicy);

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
      factory();
    });

    it('does not render edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('given a generic network policy', () => {
    beforeEach(() => {
      factory({
        propsData: {
          policy: mockGenericPolicy,
        },
      });
    });

    it('renders network policy editor with manifest', () => {
      const policyEditor = findPolicyEditor();
      expect(policyEditor.exists()).toBe(true);
      expect(policyEditor.attributes('value')).toBe(mockGenericPolicy.yaml);
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
      });
    });

    it(`renders the ${policyType} component`, () => {
      expect(finder().exists()).toBe(true);
    });

    itRendersEditButton();
  });
});
