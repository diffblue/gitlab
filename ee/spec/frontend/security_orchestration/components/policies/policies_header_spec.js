import { GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import PoliciesHeader from 'ee/security_orchestration/components/policies/policies_header.vue';
import ScanNewPolicyModal from 'ee/security_orchestration/components/policies/policy_project_modal.vue';
import { NEW_POLICY_BUTTON_TEXT } from 'ee/security_orchestration/components/constants';
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
  const findViewPolicyProjectButton = () => wrapper.findByTestId('view-project-policy-button');
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
        disableScanPolicyUpdate: false,
        disableSecurityPolicyProject: false,
        ...provide,
      },
      stubs: {
        GlSprintf,
        GlButton,
      },
    });
  };

  describe('project owner', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays "New policy" button with correct text and link', () => {
      expect(findNewPolicyButton().exists()).toBe(true);
      expect(findNewPolicyButton().text()).toBe(NEW_POLICY_BUTTON_TEXT);
      expect(findNewPolicyButton().attributes('href')).toBe(newPolicyPath);
    });

    it.each`
      status        | component                       | findFn                         | exists
      ${'does'}     | ${'edit policy project button'} | ${findEditPolicyProjectButton} | ${true}
      ${'does not'} | ${'view policy project button'} | ${findViewPolicyProjectButton} | ${false}
      ${'does not'} | ${'alert component'}            | ${findAlert}                   | ${false}
      ${'does'}     | ${'header'}                     | ${findHeader}                  | ${true}
    `('$status display the $component', ({ findFn, exists }) => {
      expect(findFn().exists()).toBe(exists);
    });

    it('mounts the scan new policy modal', () => {
      expect(findScanNewPolicyModal().exists()).toBe(true);
    });

    it('displays scan new policy modal when the action button is clicked', async () => {
      await findEditPolicyProjectButton().trigger('click');

      expect(findScanNewPolicyModal().props().visible).toBe(true);
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

      it('displays the alert component when scan new modal policy emits event', () => {
        expect(findAlert().text()).toBe(projectLinkSuccessText);
        expect(wrapper.emitted('update-policy-list')).toStrictEqual([
          [
            {
              hasPolicyProject: undefined,
              shouldUpdatePolicyList: true,
            },
          ],
        ]);
      });

      it('hides the previous alert when scan new modal policy is processing a new link', async () => {
        findScanNewPolicyModal().vm.$emit('updating-project');
        await nextTick();
        expect(findAlert().exists()).toBe(false);
      });
    });
  });

  describe('project user', () => {
    it('does not display "New policy" button', () => {
      createWrapper({
        provide: {
          assignedPolicyProject: { id: '1' },
          disableSecurityPolicyProject: true,
          disableScanPolicyUpdate: true,
        },
      });

      expect(findNewPolicyButton().exists()).toBe(false);
    });

    describe('with a security policy project', () => {
      beforeEach(() => {
        createWrapper({
          provide: { assignedPolicyProject: { id: '1' }, disableSecurityPolicyProject: true },
        });
      });

      it.each`
        status        | component                       | findFn                         | exists
        ${'does not'} | ${'edit policy project button'} | ${findEditPolicyProjectButton} | ${false}
        ${'does'}     | ${'view policy project button'} | ${findViewPolicyProjectButton} | ${true}
      `('$status display the $component', ({ findFn, exists }) => {
        expect(findFn().exists()).toBe(exists);
      });
    });

    describe('without a security policy project', () => {
      beforeEach(() => {
        createWrapper({
          provide: { disableSecurityPolicyProject: true },
        });
      });

      it.each`
        component                       | findFn
        ${'edit policy project button'} | ${findEditPolicyProjectButton}
        ${'view policy project button'} | ${findViewPolicyProjectButton}
      `('does not display the $component', ({ findFn }) => {
        expect(findFn().exists()).toBe(false);
      });
    });
  });
});
