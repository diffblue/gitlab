import { GlBadge, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import RequirementStatusBadge from 'ee/requirements/components/requirement_status_badge.vue';
import { mockTestReport, mockTestReportFailed, mockTestReportMissing } from '../mock_data';

const successBadgeProps = {
  variant: 'success',
  icon: 'status-success',
  text: 'satisfied',
  tooltipTitle: 'Passed on',
};

const failedBadgeProps = {
  variant: 'danger',
  icon: 'status-failed',
  text: 'failed',
  tooltipTitle: 'Failed on',
};

const missingBadgeProps = {
  variant: 'warning',
  icon: 'status_warning',
  text: 'missing',
  tooltipTitle: undefined,
};

describe('RequirementStatusBadge', () => {
  let wrapper;

  const createComponent = ({
    testReport = mockTestReport,
    lastTestReportManuallyCreated = false,
  } = {}) => {
    wrapper = shallowMount(RequirementStatusBadge, {
      propsData: {
        testReport,
        lastTestReportManuallyCreated,
      },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);
  const findGlTooltip = () => wrapper.findComponent(GlTooltip);

  describe('template', () => {
    describe.each`
      testReport               | badgeProps
      ${mockTestReport}        | ${successBadgeProps}
      ${mockTestReportFailed}  | ${failedBadgeProps}
      ${mockTestReportMissing} | ${missingBadgeProps}
    `(`when the last test report's been automatically created`, ({ testReport, badgeProps }) => {
      beforeEach(() => {
        createComponent({
          testReport,
          lastTestReportManuallyCreated: false,
        });
      });

      describe(`when test report status is ${testReport.state}`, () => {
        it(`renders GlBadge component`, () => {
          const badgeEl = findGlBadge();

          expect(badgeEl.exists()).toBe(true);
          expect(badgeEl.props('variant')).toBe(badgeProps.variant);
          expect(badgeEl.props('icon')).toBe(badgeProps.icon);
          expect(badgeEl.text()).toBe(badgeProps.text);
        });

        it('renders GlTooltip component', () => {
          const tooltipEl = findGlTooltip();

          expect(tooltipEl.exists()).toBe(Boolean(badgeProps.tooltipTitle));
          if (badgeProps.tooltipTitle) {
            expect(tooltipEl.find('b').text()).toBe(badgeProps.tooltipTitle);
            expect(tooltipEl.find('div').text()).toBe('Jun 4, 2020 10:55am UTC');
          }
        });
      });
    });

    describe(`when the last test report's been manually created`, () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders GlBadge component when status is "PASSED"', () => {
        expect(findGlBadge().exists()).toBe(true);
        expect(findGlBadge().text()).toBe('satisfied');
      });
    });
  });
});
