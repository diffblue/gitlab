import { GlAccordion, GlAccordionItem, GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineScanAlerts from 'ee/security_dashboard/components/pipeline/scan_alerts.vue';
import { trimText } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { DOC_PATH_SECURITY_SCANNER_INTEGRATION_REPORT } from 'ee/security_dashboard/constants';

const TEST_HELP_PAGE_LINK = 'http://help.com';
const TEST_SCANS_WITH_ERRORS = [
  {
    errors: ['scanner 1 - error 1', 'scanner 1 - error 2'],
    warnings: ['scanner 1 - warning 1', 'scanner 1 - warning 2'],
    name: 'foo',
  },
  {
    errors: ['scanner 2 - error 1', 'scanner 2 - error 2'],
    warnings: ['scanner 2 - warning 1', 'scanner 2 - warning 2'],
    name: 'bar',
  },
  {
    errors: ['scanner 3 - error 1', 'scanner 3 - error 2'],
    warnings: ['scanner 3 - warning 1', 'scanner 3 - warning 2'],
    name: 'baz',
  },
];

describe('ee/security_dashboard/components/pipeline_scan_alerts.vue', () => {
  let wrapper;
  let type = 'errors';

  const createWrapper = () =>
    extendedWrapper(
      shallowMount(PipelineScanAlerts, {
        propsData: {
          scans: TEST_SCANS_WITH_ERRORS,
          type,
          title: 'Test title',
          description: 'Test description %{helpPageLinkStart}link text%{helpPageLinkEnd}.',
        },
        provide: {
          securityReportHelpPageLink: TEST_HELP_PAGE_LINK,
        },
        stubs: {
          GlSprintf,
        },
      }),
    );

  const findAccordion = () => wrapper.findComponent(GlAccordion);
  const findAllAccordionItems = () => wrapper.findAllComponents(GlAccordionItem);
  const findAccordionItemsWithTitle = (title) =>
    findAllAccordionItems().filter((item) => item.props('title') === title);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findErrorList = () => wrapper.findByRole('list');
  const findHelpPageLink = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('shows the correct title for the alert', () => {
    expect(findAlert().text()).toContain('Test title');
  });

  it('shows the correct description for the alert', () => {
    expect(trimText(findAlert().text())).toContain('Test description');
  });

  it('links to the security-report help page', () => {
    expect(findHelpPageLink().attributes('href')).toBe(
      DOC_PATH_SECURITY_SCANNER_INTEGRATION_REPORT,
    );
  });

  describe('alert details', () => {
    it('shows an accordion containing a list of scans with messages', () => {
      expect(findAccordion().exists()).toBe(true);
      expect(findAllAccordionItems()).toHaveLength(TEST_SCANS_WITH_ERRORS.length);
    });

    it('shows a list containing details about each message', () => {
      expect(findErrorList().exists()).toBe(true);
    });
  });

  const sharedAlertMessagesTest = () => {
    describe.each(TEST_SCANS_WITH_ERRORS)('scan errors', (scan) => {
      const currentScanTitle = `${scan.name} (${scan[type].length})`;
      const findAllAccordionItemsForCurrentScan = () =>
        findAccordionItemsWithTitle(currentScanTitle);
      const findAccordionItemForCurrentScan = () => findAllAccordionItemsForCurrentScan().at(0);

      it(`contains an accordion item with the correct title for scan "${scan.name}"`, () => {
        expect(findAllAccordionItemsForCurrentScan()).toHaveLength(1);
      });

      it(`contains a detailed list of messages for scan "${scan.name}}"`, () => {
        expect(findAccordionItemForCurrentScan().find('ul').exists()).toBe(true);
        expect(findAccordionItemForCurrentScan().findAll('li')).toHaveLength(scan[type].length);
      });
    });
  };

  describe('when the type is errors', () => {
    it('shows a non-dismissible error alert', () => {
      expect(findAlert().props()).toMatchObject({
        variant: 'danger',
        dismissible: false,
      });
    });

    sharedAlertMessagesTest();
  });

  describe('when the type is warnings', () => {
    beforeAll(() => {
      type = 'warnings';
    });

    it('shows a non-dismissible warning alert', () => {
      expect(findAlert().props()).toMatchObject({
        variant: 'warning',
        dismissible: false,
      });
    });

    sharedAlertMessagesTest();
  });
});
