import { GlDropdown, GlModal, GlAlert } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import InstanceProjectSelector from 'ee/threat_monitoring/components/instance_project_selector.vue';
import ScanNewPolicyModal from 'ee/threat_monitoring/components/policies/scan_new_policy_modal.vue';
import assignSecurityPolicyProject from 'ee/threat_monitoring/graphql/mutations/assign_security_policy_project.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { mockAssignSecurityPolicyProjectResponses } from '../../mocks/mock_apollo';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('ScanNewPolicyModal Component', () => {
  let wrapper;
  let projectUpdatedListener;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findInstanceProjectSelector = () => wrapper.findComponent(InstanceProjectSelector);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModal = () => wrapper.findComponent(GlModal);

  const selectProject = async (
    project = {
      id: 'gid://gitlab/Project/1',
      name: 'Test 1',
    },
  ) => {
    findInstanceProjectSelector().vm.$emit('projectClicked', project);
    await wrapper.vm.$nextTick();
    findModal().vm.$emit('ok');
    await wrapper.vm.$nextTick();
  };

  const createWrapper = ({
    mutationResult = mockAssignSecurityPolicyProjectResponses.success,
    provide = {},
  } = {}) => {
    wrapper = mountExtended(ScanNewPolicyModal, {
      localVue,
      apolloProvider: createMockApollo([[assignSecurityPolicyProject, mutationResult]]),
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

    it('does not display a warning', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  it('emits close event when gl-modal emits change event', () => {
    createWrapper();
    findModal().vm.$emit('change');

    expect(wrapper.emitted('close')).toEqual([[]]);
  });

  describe('project selection', () => {
    it('enables the "Save" button only if a new project is selected', async () => {
      createWrapper({
        provide: { assignedPolicyProject: { id: 'gid://gitlab/Project/0', name: 'Test 0' } },
      });

      expect(findModal().attributes('ok-disabled')).toBe('true');

      findInstanceProjectSelector().vm.$emit('projectClicked', {
        id: 'gid://gitlab/Project/1',
        name: 'Test 1',
      });

      await wrapper.vm.$nextTick();

      expect(findModal().attributes('ok-disabled')).toBeUndefined();
    });

    it('emits an event with success message', async () => {
      await createWrapperAndSelectProject();

      expect(projectUpdatedListener).toHaveBeenCalledWith({
        text: 'Security policy project was linked successfully',
        variant: 'success',
      });
    });

    it('emits an event with an error message', async () => {
      await createWrapperAndSelectProject({
        mutationResult: mockAssignSecurityPolicyProjectResponses.failure,
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
