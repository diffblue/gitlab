import { GlAlert, GlSprintf, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ReportStatusAlert from 'ee/security_dashboard/components/pipeline/report_status_alert.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import { DOC_PATH_SECURITY_SCANNER_INTEGRATION_RETENTION_PERIOD } from 'ee/security_dashboard/constants';

describe('ee/security_dashboard/components/report_status_alert.vue', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findHelpPageLink = () => wrapper.findComponent(GlButton);
  const findAlertText = () => trimText(findAlert().text());
  const createWrapper = () =>
    extendedWrapper(
      shallowMount(ReportStatusAlert, {
        stubs: {
          GlSprintf,
        },
      }),
    );

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('renders the component correctly', () => {
    expect(wrapper).toMatchSnapshot();
  });

  it('shows the correct title for the alert', () => {
    expect(findAlertText()).toContain('Report has expired');
  });

  it('shows the correct description for the alert', () => {
    expect(findAlertText()).toContain(
      'The security report for this pipeline has expired . Re-run the pipeline to generate a new security report.',
    );
  });

  it('links to the security-report help page', () => {
    expect(findHelpPageLink().attributes('href')).toBe(
      DOC_PATH_SECURITY_SCANNER_INTEGRATION_RETENTION_PERIOD,
    );
  });
});
