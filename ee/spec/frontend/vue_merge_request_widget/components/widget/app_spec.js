import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from 'ee/vue_merge_request_widget/components/widget/app.vue';
import MrSecurityWidgetEE from 'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue';
import MrSecurityWidgetCE from '~/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue';

describe('MR Widget App', () => {
  let wrapper;

  const createComponent = ({ mr } = {}) => {
    wrapper = shallowMountExtended(App, {
      propsData: {
        mr: {
          securityConfigurationPath: '/help/user/application_security/index.md',
          sourceProjectFullPath: 'namespace/project',
          pipeline: {
            path: '/path/to/pipeline',
          },
          ...mr,
        },
      },
    });
  };

  describe('MRSecurityWidget', () => {
    it('mounts MrSecurityWidgetEE when user has necessary permissions', async () => {
      createComponent({
        mr: {
          canReadVulnerabilities: true,
        },
      });
      await waitForPromises();
      expect(wrapper.findComponent(MrSecurityWidgetEE).exists()).toBe(true);
    });

    it('mounts MrSecurityWidgetCE when user does not have necessary permissions', async () => {
      createComponent({
        mr: {
          canReadVulnerabilities: false,
        },
      });
      await waitForPromises();
      expect(wrapper.findComponent(MrSecurityWidgetCE).exists()).toBe(true);
    });
  });
});
