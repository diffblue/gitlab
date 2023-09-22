import { GlButton, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SettingPopover from 'ee/security_orchestration/components/policy_editor/scan_result/settings/setting_popover.vue';

describe('SettingPopover', () => {
  let wrapper;
  let userCalloutDismissSpy;
  const description = '%{linkStart}Learn more.%{linkEnd}';

  const createComponent = ({ propsData = {}, shouldShowCallout = true } = {}) => {
    userCalloutDismissSpy = jest.fn();

    wrapper = shallowMountExtended(SettingPopover, {
      propsData: {
        description,
        featureName: 'branchModification',
        id: 'this-is-the-target',
        title: 'Best popover',
        ...propsData,
      },
      stubs: {
        GlPopover,
        GlSprintf,
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findLink = () => wrapper.findComponent(GlLink);
  const findPopover = () => wrapper.findComponent(GlPopover);

  describe('default', () => {
    it('does not display by default', () => {
      createComponent();
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().props('show')).toBe(false);
    });

    it('displays if "showPopover" is true', () => {
      createComponent({ propsData: { showPopover: true } });
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().props('show')).toBe(true);
    });

    it('does not display if it has been permanently dismissed', () => {
      createComponent({ propsData: { showPopover: true }, shouldShowCallout: false });
      expect(findPopover().exists()).toBe(false);
    });

    it('navigates the user to the policies page when they click the popover link', () => {
      const link = helpPagePath('/user/application_security/policies/scan-result-policies.html');
      createComponent({ propsData: { description, link, showPopover: true } });
      expect(findLink().text()).toContain('Learn more.');
      expect(findLink().attributes('href')).toBe(link);
    });

    it('permanently dismisses the popover when the popover button is clicked', async () => {
      createComponent({ propsData: { propsData: { showPopover: true } } });
      await findButton().vm.$emit('click');
      expect(userCalloutDismissSpy).toHaveBeenCalled();
    });
  });
});
