import { GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { NEW_POLICY_BUTTON_TEXT } from 'ee/threat_monitoring/components/constants';
import PoliciesHeader from 'ee/threat_monitoring/components/policies/policies_header.vue';
import ScanNewPolicyModal from 'ee/threat_monitoring/components/policies/scan_new_policy_modal.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Policies Header Component', () => {
  let wrapper;

  const documentationPath = '/path/to/docs';
  const newPolicyPath = '/path/to/new/policy/page';
  const projectLinkSuccessText = 'Project was linked successfully.';

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findScanNewPolicyModal = () => wrapper.findComponent(ScanNewPolicyModal);
  const findHeader = () => wrapper.findByRole('heading');
  const findMoreInformationLink = () => wrapper.findComponent(GlButton);
  const findEditPolicyProjectButton = () => wrapper.findByTestId('edit-project-policy-button');
  const findNewPolicyButton = () => wrapper.findByTestId('new-policy-button');
  const findSubheader = () => wrapper.findByTestId('policies-subheader');

  const linkSecurityPoliciesProject = async () => {
    findScanNewPolicyModal().vm.$emit('project-updated', {
      text: projectLinkSuccessText,
      variant: 'success',
    });
    await nextTick();
  };

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
      expect(findNewPolicyButton().text()).toBe(NEW_POLICY_BUTTON_TEXT);
      expect(findNewPolicyButton().attributes('href')).toBe(newPolicyPath);
    });

    it('displays the Edit policy project button', () => {
      expect(findEditPolicyProjectButton().text()).toBe('Edit policy project');
    });

    it('does not display the alert component by default', () => {
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
      expect(findSubheader().text()).toMatchInterpolatedText(
        'Enforce security for this project. More information.',
      );
      expect(findMoreInformationLink().attributes('href')).toBe(documentationPath);
    });

    describe('linking security policies project', () => {
      beforeEach(async () => {
        await linkSecurityPoliciesProject();
      });

      it('displays the alert component when scan new modal policy emits event', async () => {
        expect(findAlert().text()).toBe(projectLinkSuccessText);
        expect(wrapper.emitted('update-policy-list')).toStrictEqual([[true]]);
      });

      it('hides the previous alert when scan new modal policy is processing a new link', async () => {
        findScanNewPolicyModal().vm.$emit('updating-project');
        await nextTick();
        expect(findAlert().exists()).toBe(false);
      });
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
