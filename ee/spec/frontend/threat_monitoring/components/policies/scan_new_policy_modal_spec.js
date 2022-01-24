import { GlDropdown, GlModal, GlAlert } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import InstanceProjectSelector from 'ee/threat_monitoring/components/instance_project_selector.vue';
import ScanNewPolicyModal from 'ee/threat_monitoring/components/policies/scan_new_policy_modal.vue';
import linkSecurityPolicyProject from 'ee/threat_monitoring/graphql/mutations/link_security_policy_project.mutation.graphql';
import unlinkSecurityPolicyProject from 'ee/threat_monitoring/graphql/mutations/unlink_security_policy_project.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  mockLinkSecurityPolicyProjectResponses,
  mockUnlinkSecurityPolicyProjectResponses,
} from '../../mocks/mock_apollo';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('ScanNewPolicyModal Component', () => {
  let wrapper;
  let projectUpdatedListener;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findInstanceProjectSelector = () => wrapper.findComponent(InstanceProjectSelector);
  const findUnlinkButton = () => wrapper.findByLabelText('Unlink project');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModal = () => wrapper.findComponent(GlModal);

  const selectProject = async ({
    project = {
      id: 'gid://gitlab/Project/1',
      name: 'Test 1',
    },
    shouldSubmit = true,
  } = {}) => {
    findInstanceProjectSelector().vm.$emit('projectClicked', project);
    await waitForPromises();

    if (shouldSubmit) {
      findModal().vm.$emit('ok');
      await waitForPromises();
    }
  };

  const createWrapper = ({
    mutationQuery = linkSecurityPolicyProject,
    mutationResult = mockLinkSecurityPolicyProjectResponses.success,
    provide = {},
  } = {}) => {
    wrapper = mountExtended(ScanNewPolicyModal, {
      localVue,
      apolloProvider: createMockApollo([[mutationQuery, mutationResult]]),
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
      provide: {
        disableSecurityPolicyProject: false,
        documentationPath: 'test/path/index.md',
        projectPath: 'path/to/project',
        assignedPolicyProject: null,
        ...provide,
      },
    });

    projectUpdatedListener = jest.fn();
    wrapper.vm.$on('project-updated', projectUpdatedListener);
  };

  const createWrapperAndSelectProject = async (data) => {
    createWrapper(data);
    await selectProject();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('passes down correct properties/attributes to the gl-modal component', () => {
      expect(findModal().props()).toMatchObject({
        modalId: 'scan-new-policy',
        size: 'sm',
        visible: false,
        title: 'Select security project',
      });

      expect(findModal().attributes()).toEqual({
        'ok-disabled': 'true',
        'ok-title': 'Save',
        'cancel-variant': 'light',
      });
    });

    it('displays a placeholder when no project is selected', () => {
      expect(findDropdown().props('text')).toBe('Choose a project');
    });

    it('does not display a warning', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  it('emits close event when gl-modal emits change event', async () => {
    createWrapper();
    await selectProject({ shouldSubmit: false });

    findModal().vm.$emit('change');
    expect(wrapper.emitted('close')).toEqual([[]]);
    expect(findInstanceProjectSelector().props('selectedProjects')[0].name).toBe('Test 1');

    // should restore the previous state when action is not submitted
    await wrapper.vm.$nextTick();
    expect(findInstanceProjectSelector().props('selectedProjects')[0].name).toBeUndefined();
  });

  describe('unlinking project', () => {
    it.each`
      mutationResult | expectedVariant | expectedText
      ${'success'}   | ${'success'}    | ${'okUnlink'}
      ${'failure'}   | ${'danger'}     | ${'errorUnlink'}
    `(
      'unlinks a project and handles $mutationResult case',
      async ({ mutationResult, expectedVariant, expectedText }) => {
        createWrapper({
          mutationQuery: unlinkSecurityPolicyProject,
          mutationResult: mockUnlinkSecurityPolicyProjectResponses[mutationResult],
          provide: { assignedPolicyProject: { id: 'gid://gitlab/Project/0', name: 'Test 0' } },
        });

        // Initial state
        expect(findModal().attributes('ok-disabled')).toBe('true');
        expect(wrapper.findByText(wrapper.vm.$options.i18n.unlinkWarning).exists()).toBe(false);

        // When we click on the delete button, the component should display a warning
        findUnlinkButton().trigger('click');
        await wrapper.vm.$nextTick();

        expect(wrapper.findByText(wrapper.vm.$options.i18n.unlinkWarning).exists()).toBe(true);
        expect(findModal().attributes('ok-disabled')).toBeUndefined();

        // Clicking the OK button should submit a GraphQL query
        findModal().vm.$emit('ok');
        await waitForPromises();

        expect(projectUpdatedListener).toHaveBeenCalledWith({
          text: wrapper.vm.$options.i18n.save[expectedText],
          variant: expectedVariant,
        });
      },
    );
  });

  describe('project selection', () => {
    it('enables the "Save" button only if a new project is selected', async () => {
      createWrapper({
        provide: { assignedPolicyProject: { id: 'gid://gitlab/Project/0', name: 'Test 0' } },
      });
      await waitForPromises();

      expect(findModal().attributes('ok-disabled')).toBe('true');

      findInstanceProjectSelector().vm.$emit('projectClicked', {
        id: 'gid://gitlab/Project/1',
        name: 'Test 1',
      });

      await waitForPromises();

      expect(findModal().attributes('ok-disabled')).toBeUndefined();
    });

    it('emits an event with success message', async () => {
      await createWrapperAndSelectProject();

      expect(projectUpdatedListener).toHaveBeenCalledWith({
        text: 'Security policy project was linked successfully',
        variant: 'success',
      });

      expect(findInstanceProjectSelector().props('selectedProjects')).toEqual([
        { id: 'gid://gitlab/Project/1', name: 'Test 1' },
      ]);
    });

    it('emits an event with an error message', async () => {
      await createWrapperAndSelectProject({
        mutationResult: mockLinkSecurityPolicyProjectResponses.failure,
      });

      expect(projectUpdatedListener).toHaveBeenCalledWith({
        text: 'An error occurred assigning your security policy project',
        variant: 'danger',
      });
    });
  });

  describe('disabled', () => {
    beforeEach(() => {
      createWrapper({ provide: { disableSecurityPolicyProject: true } });
    });

    it('disables the dropdown', () => {
      expect(findDropdown().props('disabled')).toBe(true);
    });

    it('displays a warning', () => {
      expect(findAlert().text()).toBe('Only owners can update Security Policy Project');
    });
  });
});
