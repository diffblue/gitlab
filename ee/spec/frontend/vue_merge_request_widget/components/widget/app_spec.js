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

  it('does not mount if widgets array is empty', () => {
    createComponent();
    expect(wrapper.findByTestId('mr-widget-app').exists()).toBe(false);
  });

  describe('MRSecurityWidget', () => {
    beforeEach(() => {
      window.gon = { features: { refactorSecurityExtension: true } };
    });

    it('mounts MrSecurityWidgetEE when user has necessary permissions and reports are enabled', async () => {
      createComponent({
        mr: {
          canReadVulnerabilities: true,
          enabledReports: {
            sast: true,
          },
        },
      });
      await waitForPromises();
      expect(wrapper.findComponent(MrSecurityWidgetEE).exists()).toBe(true);
    });

    it('mounts MrSecurityWidgetCE when user does not have necessary permissions', async () => {
      createComponent({
        mr: {
          canReadVulnerabilities: false,
          enabledReports: {
            sast: true,
          },
        },
      });
      await waitForPromises();
      expect(wrapper.findComponent(MrSecurityWidgetCE).exists()).toBe(true);
    });

    it('mounts MrSecurityWidgetCE when reports are not enabled', async () => {
      createComponent({
        mr: {
          canReadVulnerabilities: true,
        },
      });
      await waitForPromises();
      expect(wrapper.findComponent(MrSecurityWidgetCE).exists()).toBe(true);
    });

    it('does not mount security reports when feature flag is not enabled', async () => {
      window.gon = { features: { refactorSecurityExtension: false } };
      createComponent();
      await waitForPromises();
      expect(wrapper.findComponent(MrSecurityWidgetEE).exists()).toBe(false);
      expect(wrapper.findComponent(MrSecurityWidgetCE).exists()).toBe(false);
    });
  });
});
