import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from 'ee/vue_merge_request_widget/components/widget/app.vue';
import MrSecurityWidget from 'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue';

describe('MR Widget App', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(App, {
      propsData: {
        mr: {
          securityConfigurationPath: '/help/user/application_security/index.md',
          sourceProjectFullPath: 'namespace/project',
        },
      },
    });
  };

  it('does not mount if widgets array is empty', () => {
    createComponent();
    expect(wrapper.findByTestId('mr-widget-app').exists()).toBe(false);
  });

  describe.each`
    featureFlag                    | component           | componentName
    ${'refactorSecurityExtension'} | ${MrSecurityWidget} | ${'MrSecurityWidget'}
  `('mounts $componentName', ({ component, featureFlag, componentName }) => {
    afterEach(() => {
      delete window.gon;
    });

    it(`mounts ${componentName} when ${featureFlag} is true`, async () => {
      window.gon = { features: { [featureFlag]: true } };
      createComponent();
      await waitForPromises();
      expect(wrapper.findComponent(component).exists()).toBe(true);
    });

    it(`does not mount ${componentName} when ${featureFlag} is false`, async () => {
      window.gon = { features: { [featureFlag]: false } };
      createComponent();
      await waitForPromises();
      expect(wrapper.findComponent(component).exists()).toBe(false);
    });
  });
});
