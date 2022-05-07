import { mount } from '@vue/test-utils';
import { GlLink, GlAlert } from '@gitlab/ui';
import SecurityScannerAlert from 'ee/security_dashboard/components/project/security_scanner_alert.vue';

describe('EE Vulnerability Security Scanner Alert', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  const createWrapper = ({ props = {}, provide = {} } = {}) => {
    wrapper = mount(SecurityScannerAlert, {
      propsData: {
        notEnabledScanners: [],
        noPipelineRunScanners: [],
        ...props,
      },
      provide: () => ({
        notEnabledScannersHelpPath: '',
        noPipelineRunScannersHelpPath: '',
        ...provide,
      }),
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAlertLink = () => wrapper.findComponent(GlLink);

  describe('container', () => {
    it('renders when disabled scanners are detected', () => {
      createWrapper({ props: { notEnabledScanners: ['SAST'], noPipelineRunScanners: [] } });

      expect(findAlert().exists()).toBe(true);
    });

    it('renders when scanners without pipeline runs are detected', () => {
      createWrapper({ props: { notEnabledScanners: [], noPipelineRunScanners: ['DAST'] } });

      expect(findAlert().exists()).toBe(true);
    });

    it('does not render when all scanners are enabled', () => {
      createWrapper({ props: { notEnabledScanners: [], noPipelineRunScanners: [] } });

      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('dismissal', () => {
    it('emits when the alert is dismissed', () => {
      createWrapper({ props: { notEnabledScanners: ['SAST'] } });
      findAlert().vm.$emit('dismiss');

      expect(wrapper.emitted('dismiss')).toHaveLength(1);
    });
  });

  describe('alert text', () => {
    it.each`
      givenScanners                                  | expectedTextContained
      ${{ notEnabledScanners: ['SAST'] }}            | ${'SAST is not enabled for this project'}
      ${{ notEnabledScanners: ['SAST', 'DAST'] }}    | ${'SAST, DAST are not enabled for this project'}
      ${{ noPipelineRunScanners: ['SAST'] }}         | ${'SAST result is not available because a pipeline has not been run since it was enabled'}
      ${{ noPipelineRunScanners: ['SAST', 'DAST'] }} | ${'SAST, DAST results are not available because a pipeline has not been run since it was enabled'}
    `('renders the correct warning', ({ givenScanners, expectedTextContained }) => {
      createWrapper({ props: { ...givenScanners } });

      expect(findAlert().text()).toContain(expectedTextContained);
    });
  });

  describe('help links', () => {
    it.each`
      alertType          | linkText
      ${'notEnabled'}    | ${'More information'}
      ${'noPipelineRun'} | ${'Run a pipeline'}
    `('link for $alertType scanners renders correctly', ({ alertType, linkText }) => {
      const link = 'http://foo.com/';
      createWrapper({
        props: { [`${alertType}Scanners`]: ['SAST'] },
        provide: { [`${alertType}ScannersHelpPath`]: link },
      });

      expect(findAlertLink().text()).toBe(linkText);
      expect(findAlertLink().attributes('href')).toBe(link);
    });
  });
});
