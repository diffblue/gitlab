import { within } from '@testing-library/dom';
import { GlIcon } from '@gitlab/ui';
import ReportSection from 'ee/vulnerabilities/components/generic_report/report_section_graphql.vue';
import { vulnerabilityDetailUrl } from 'ee_jest/security_dashboard/components/pipeline/mock_data';
import { mountExtended } from 'helpers/vue_test_utils_helper';

const TEST_DATA = {
  supportedTypes: [vulnerabilityDetailUrl],
  unsupportedTypes: [
    {
      type: 'Unsupported',
      name: 'four',
    },
  ],
};

describe('ee/vulnerabilities/components/generic_report/report_section_graphql.vue', () => {
  let wrapper;

  const createWrapper = (options) =>
    mountExtended(ReportSection, {
      propsData: {
        reportItems: [...TEST_DATA.supportedTypes, ...TEST_DATA.unsupportedTypes],
      },
      ...options,
    });

  const withinWrapper = () => within(wrapper.element);
  const findHeader = () => wrapper.find('header');
  const findHeading = () =>
    withinWrapper().getByRole('heading', {
      name: /evidence/i,
    });
  const findReportsSection = () => wrapper.findByTestId('reports');
  const findAllReportRows = () => wrapper.findAll('[data-testid*="report-row"]');
  const findReportRowByType = (type) => wrapper.findByTestId(`report-row-${type}`);
  const findReportItemByType = (type) => wrapper.findByTestId(`report-item-${type}`);

  describe('with supported report types', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    describe('reports section', () => {
      it('contains a heading', () => {
        expect(findHeading()).toBeInstanceOf(HTMLElement);
      });

      it('contains an icon to indicate that the section can be collapsed', () => {
        expect(findHeader().findComponent(GlIcon).exists()).toBe(true);
      });

      it('collapses when the header is clicked', async () => {
        expect(findReportsSection().isVisible()).toBe(true);

        await findHeader().trigger('click');

        expect(findReportsSection().isVisible()).toBe(false);
      });
    });

    describe('report rows', () => {
      it('only renders valid report types', () => {
        expect(findAllReportRows()).toHaveLength(TEST_DATA.supportedTypes.length);
      });

      it.each(TEST_DATA.supportedTypes)(
        'renders the correct label for report row: %s',
        ({ type, name }) => {
          expect(within(findReportRowByType(type).element).getByText(name)).toBeInstanceOf(
            HTMLElement,
          );
        },
      );
    });

    describe('report items', () => {
      it.each(TEST_DATA.supportedTypes)(
        'passes the correct props to item for row: %s',
        (supportedType) => {
          expect(findReportItemByType(supportedType.type).props()).toMatchObject({
            item: supportedType,
          });
        },
      );
    });
  });

  describe('with only unsupported report types', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        propsData: {
          reportItems: TEST_DATA.unsupportedTypes,
        },
      });
    });

    it('should not render', () => {
      expect(findReportsSection().exists()).toBe(false);
    });
  });
});
