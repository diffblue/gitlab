import { GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import PoliciesHeader from 'ee/threat_monitoring/components/policies/policies_header.vue';
import ScanNewPolicyModal from 'ee/threat_monitoring/components/policies/scan_new_policy_modal.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Policies Header Component', () => {
  let wrapper;

  const documentationPath = '/path/to/docs';
  const newPolicyPath = '/path/to/new/policy/page';

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findScanNewPolicyModal = () => wrapper.findComponent(ScanNewPolicyModal);
  const findHeader = () => wrapper.findByRole('heading');
  const findMoreInformationLink = () => wrapper.findComponent(GlButton);
  const findEditPolicyProjectButton = () => wrapper.findByTestId('edit-project-policy-button');
  const findNewPolicyButton = () => wrapper.findByTestId('new-policy-button');
  const findSubheader = () => wrapper.findByTestId('policies-subheader');

  const createWrapper = ({ provide } = {}) => {
    wrapper = shallowMountExtended(PoliciesHeader, {
      provide: {
        documentationPath,
        newPolicyPath,
        assignedPolicyProject: null,
        disableSecurityPolicyProject: false,
        ...provide,
      },
      stubs: {
        GlSprintf,
        GlButton,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('project owner', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays New policy button with correct text and link', () => {
      expect(findNewPolicyButton().text()).toBe('New policy');
      expect(findNewPolicyButton().attributes('href')).toBe(newPolicyPath);
    });

    it('displays the Edit policy project button', () => {
      expect(findEditPolicyProjectButton().text()).toBe('Edit policy project');
    });

    it('does not display the alert component by default', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('displays the alert component when scan new modal policy emits events', async () => {
      const text = 'Project was linked successfully.';

      findScanNewPolicyModal().vm.$emit('project-updated', {
        text,
        variant: 'success',
      });

      // When the project is updated it displays the output message.
      await wrapper.vm.$nextTick();
      expect(findAlert().text()).toBe(text);

      // When the project is being updated once again, it removes the alert so that
      // the new one will be displayed.
      findScanNewPolicyModal().vm.$emit('updating-project');
      await wrapper.vm.$nextTick();
      expect(findAlert().exists()).toBe(false);
    });

    it('mounts the scan new policy modal', () => {
      expect(findScanNewPolicyModal().exists()).toBe(true);
    });

    it('displays scan new policy modal when the action button is clicked', async () => {
      await findEditPolicyProjectButton().trigger('click');

      expect(findScanNewPolicyModal().props().visible).toBe(true);
    });

    it('displays the header', () => {
      expect(findHeader().text()).toBe('Policies');
    });

    it('displays the subheader', () => {
      expect(findSubheader().text()).toContain('Enforce security for this project.');
      expect(findMoreInformationLink().attributes('href')).toBe(documentationPath);
    });
  });

  describe('project user', () => {
    beforeEach(() => {
      createWrapper({ provide: { disableSecurityPolicyProject: true } });
    });

    it('does not display the Edit policy project button', () => {
      expect(findEditPolicyProjectButton().exists()).toBe(false);
    });
  });
});
