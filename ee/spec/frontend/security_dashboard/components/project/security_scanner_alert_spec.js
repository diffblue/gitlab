import { mount } from '@vue/test-utils';
import { GlLink, GlAlert } from '@gitlab/ui';
import SecurityScannerAlert from 'ee/security_dashboard/components/project/security_scanner_alert.vue';
import { DOC_PATH_APPLICATION_SECURITY } from 'ee/security_dashboard/constants';

describe('EE Vulnerability Security Scanner Alert', () => {
  let wrapper;

  const createWrapper = ({ props = {}, provide = {} } = {}) => {
    wrapper = mount(SecurityScannerAlert, {
      propsData: {
        notEnabledScanners: [],
        noPipelineRunScanners: [],
        ...props,
      },
      provide: () => ({
        newProjectPipelinePath: '',
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
    const newProjectPipelinePath = 'http://foo.com/';

    it.each`
      alertType          | linkText              | link
      ${'notEnabled'}    | ${'More information'} | ${DOC_PATH_APPLICATION_SECURITY}
      ${'noPipelineRun'} | ${'Run a pipeline'}   | ${newProjectPipelinePath}
    `('link for $alertType scanners renders correctly', ({ alertType, linkText, link }) => {
      createWrapper({
        props: { [`${alertType}Scanners`]: ['SAST'] },
        provide: { newProjectPipelinePath },
      });

      expect(findAlertLink().text()).toBe(linkText);
      expect(wrapper.findComponent(GlLink).attributes('href')).toBe(link);
    });
  });
});
