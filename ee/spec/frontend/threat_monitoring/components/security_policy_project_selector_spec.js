import { GlDropdown } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import InstanceProjectSelector from 'ee/threat_monitoring/components/instance_project_selector.vue';
import SecurityPolicyProjectSelector from 'ee/threat_monitoring/components/security_policy_project_selector.vue';
import assignSecurityPolicyProject from 'ee/threat_monitoring/graphql/mutations/assign_security_policy_project.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  apolloFailureResponse,
  mockAssignSecurityPolicyProjectResponses,
} from '../mocks/mock_apollo';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('SecurityPolicyProjectSelector Component', () => {
  let wrapper;

  const findSaveButton = () => wrapper.findByTestId('save-policy-project');
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findErrorAlert = () => wrapper.findByTestId('policy-project-assign-error');
  const findInstanceProjectSelector = () => wrapper.findComponent(InstanceProjectSelector);
  const findSuccessAlert = () => wrapper.findByTestId('policy-project-assign-success');
  const findTooltip = () => wrapper.findByTestId('disabled-button-tooltip');

  const selectProject = async () => {
    findInstanceProjectSelector().vm.$emit('projectClicked', {
      id: 'gid://gitlab/Project/1',
      name: 'Test 1',
    });
    await wrapper.vm.$nextTick();
    findSaveButton().vm.$emit('click');
    await waitForPromises();
  };

  const createWrapper = ({
    mount = shallowMountExtended,
    mutationResult = mockAssignSecurityPolicyProjectResponses.success,
    propsData = {},
    provide = {},
  } = {}) => {
    wrapper = mount(SecurityPolicyProjectSelector, {
      localVue,
      apolloProvider: createMockApollo([[assignSecurityPolicyProject, mutationResult]]),
      directives: {
        GlTooltip: createMockDirective(),
      },
      propsData,
      provide: {
        disableSecurityPolicyProject: false,
        documentationPath: 'test/path/index.md',
        projectPath: 'path/to/project',
        ...provide,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it.each`
      findComponent                  | state    | title
      ${findDropdown}                | ${true}  | ${'does display the dropdown'}
      ${findInstanceProjectSelector} | ${true}  | ${'does display the project selector'}
      ${findErrorAlert}              | ${false} | ${'does not display the error alert'}
      ${findSuccessAlert}            | ${false} | ${'does not display the success alert'}
    `('$title', ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
    });

    it('renders the "Save Changes" button', () => {
      const button = findSaveButton();
      expect(button.exists()).toBe(true);
      expect(button.attributes('disabled')).toBe('true');
    });

    it('does not display a tooltip', () => {
      const tooltip = getBinding(findTooltip().element, 'gl-tooltip');
      expect(tooltip.value.disabled).toBe(true);
    });
  });

  describe('project selection', () => {
    it('enables the "Save Changes" button if a new project is selected', async () => {
      createWrapper({
        mount: mountExtended,
        propsData: { assignedPolicyProject: { id: 'gid://gitlab/Project/0', name: 'Test 0' } },
      });
      const button = findSaveButton();
      expect(button.attributes('disabled')).toBe('disabled');
      findInstanceProjectSelector().vm.$emit('projectClicked', {
        id: 'gid://gitlab/Project/1',
        name: 'Test 1',
      });
      await wrapper.vm.$nextTick();
      expect(button.attributes('disabled')).toBe(undefined);
    });

    it('displays an alert if the security policy project selection succeeds', async () => {
      createWrapper({ mount: mountExtended });
      expect(findErrorAlert().exists()).toBe(false);
      expect(findSuccessAlert().exists()).toBe(false);
      await selectProject();
      expect(findErrorAlert().exists()).toBe(false);
      expect(findSuccessAlert().exists()).toBe(true);
    });

    it('shows an alert if the security policy project selection fails', async () => {
      createWrapper({
        mount: mountExtended,
        mutationResult: mockAssignSecurityPolicyProjectResponses.failure,
      });
      expect(findErrorAlert().exists()).toBe(false);
      expect(findSuccessAlert().exists()).toBe(false);
      await selectProject();
      expect(findErrorAlert().exists()).toBe(true);
      expect(findSuccessAlert().exists()).toBe(false);
    });

    it('shows an alert if GraphQL fails', async () => {
      createWrapper({ mount: mountExtended, mutationResult: apolloFailureResponse });
      expect(findErrorAlert().exists()).toBe(false);
      expect(findSuccessAlert().exists()).toBe(false);
      await selectProject();
      expect(findErrorAlert().exists()).toBe(true);
      expect(findSuccessAlert().exists()).toBe(false);
    });
  });

  describe('disabled', () => {
    beforeEach(() => {
      createWrapper({ provide: { disableSecurityPolicyProject: true } });
    });

    it('disables the dropdown', () => {
      expect(findDropdown().attributes('disabled')).toBe('true');
    });

    it('displays a tooltip', () => {
      const tooltip = getBinding(findTooltip().element, 'gl-tooltip');
      expect(tooltip.value.disabled).toBe(false);
    });
  });
});
