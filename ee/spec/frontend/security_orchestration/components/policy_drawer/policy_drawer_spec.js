import { GlButton, GlDrawer, GlTabs, GlTab } from '@gitlab/ui';
import PolicyDrawer from 'ee/security_orchestration/components/policy_drawer/policy_drawer.vue';
import ScanExecutionPolicy from 'ee/security_orchestration/components/policy_drawer/scan_execution_policy.vue';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockProjectScanExecutionPolicy,
  mockGroupScanExecutionPolicy,
} from '../../mocks/mock_scan_execution_policy_data';

describe('PolicyDrawer component', () => {
  let wrapper;

  const factory = ({ mountFn = shallowMountExtended, propsData, stubs = {} } = {}) => {
    wrapper = mountFn(PolicyDrawer, {
      propsData: {
        editPolicyPath: '/policies/policy-name/edit?type="scanExecution"',
        open: true,
        ...propsData,
      },
      stubs: { PolicyYamlEditor: true, GlTooltip: true, ...stubs },
    });
  };

  // Finders
  const findEditButton = () => wrapper.findByTestId('edit-button');
  const findTooltip = () => wrapper.findByTestId('edit-button-tooltip');
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findScanExecutionPolicy = () => wrapper.findComponent(ScanExecutionPolicy);
  const findDefaultComponentPolicyEditor = () =>
    wrapper.findByTestId('policy-yaml-editor-default-component');
  const findTabPolicyEditor = () => wrapper.findByTestId('policy-yaml-editor-tab-content');

  // Shared assertions
  const itRendersEditButton = () => {
    it('renders edit button', () => {
      const button = findEditButton();
      expect(button.exists()).toBe(true);
      expect(button.attributes().href).toBe('/policies/policy-name/edit?type="scanExecution"');
    });
  };

  describe('without a policy', () => {
    beforeEach(() => {
      factory({ stubs: { GlDrawer } });
    });

    it('does not render edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('given a generic policy', () => {
    beforeEach(() => {
      factory({
        mountFn: mountExtended,
        propsData: {
          policy: mockProjectScanExecutionPolicy,
        },
      });
    });

    it('renders policy editor with manifest', () => {
      expect(findDefaultComponentPolicyEditor().attributes('value')).toBe(
        mockProjectScanExecutionPolicy.yaml,
      );
    });

    itRendersEditButton();

    it('does not render the edit button tooltip', () => {
      expect(findTooltip().exists()).toBe(false);
    });
  });

  describe.each`
    policyType                                           | mock                              | finder
    ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value} | ${mockProjectScanExecutionPolicy} | ${findScanExecutionPolicy}
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

  describe('inherited policy', () => {
    beforeEach(() => {
      factory({
        mountFn: mountExtended,
        propsData: {
          policy: mockGroupScanExecutionPolicy,
        },
      });
    });

    it('renders a disabled edit button', () => {
      const button = findEditButton();
      expect(button.exists()).toBe(true);
      expect(button.props('disabled')).toBe(true);
    });

    it('renders the edit button tooltip', () => {
      expect(findTooltip().exists()).toBe(true);
    });
  });
});
