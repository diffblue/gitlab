import { GlBadge, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import RequirementStatusBadge from 'ee/requirements/components/requirement_status_badge.vue';
import { mockTestReport, mockTestReportFailed, mockTestReportMissing } from '../mock_data';

const createComponent = ({
  testReport = mockTestReport,
  lastTestReportManuallyCreated = false,
} = {}) =>
  shallowMount(RequirementStatusBadge, {
    propsData: {
      testReport,
      lastTestReportManuallyCreated,
    },
  });

const findGlBadge = (wrapper) => wrapper.findComponent(GlBadge);
const findGlTooltip = (wrapper) => wrapper.findComponent(GlTooltip);

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

describe('RequirementStatusBadge', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('computed', () => {
    describe('testReportBadge', () => {
      it('returns object containing variant, icon, text and tooltipTitle when status is "PASSED"', () => {
        expect(wrapper.vm.testReportBadge).toEqual(successBadgeProps);
      });

      it('returns object containing variant, icon, text and tooltipTitle when status is "FAILED"', async () => {
        wrapper.setProps({
          testReport: mockTestReportFailed,
        });

        await nextTick();
        expect(wrapper.vm.testReportBadge).toEqual(failedBadgeProps);
      });

      it('returns object containing variant, icon, text and tooltipTitle when status missing', async () => {
        wrapper.setProps({
          testReport: mockTestReportMissing,
        });

        await nextTick();
        expect(wrapper.vm.testReportBadge).toEqual({
          variant: 'warning',
          icon: 'status_warning',
          text: 'missing',
          tooltipTitle: '',
        });
      });
    });
  });

  describe('template', () => {
    describe.each`
      testReport              | badgeProps
      ${mockTestReport}       | ${successBadgeProps}
      ${mockTestReportFailed} | ${failedBadgeProps}
    `(`when the last test report's been automatically created`, ({ testReport, badgeProps }) => {
      beforeEach(() => {
        wrapper = createComponent({
          testReport,
          lastTestReportManuallyCreated: false,
        });
      });

      describe(`when test report status is ${testReport.state}`, () => {
        it(`renders GlBadge component`, () => {
          const badgeEl = findGlBadge(wrapper);

          expect(badgeEl.exists()).toBe(true);
          expect(badgeEl.props('variant')).toBe(badgeProps.variant);
          expect(badgeEl.props('icon')).toBe(badgeProps.icon);
          expect(badgeEl.text()).toBe(badgeProps.text);
        });

        it('renders GlTooltip component', () => {
          const tooltipEl = findGlTooltip(wrapper);

          expect(tooltipEl.exists()).toBe(true);
          expect(tooltipEl.find('b').text()).toBe(badgeProps.tooltipTitle);
          expect(tooltipEl.find('div').text()).toBe('Jun 4, 2020 10:55am UTC');
        });
      });
    });

    describe(`when the last test report's been manually created`, () => {
      it('renders GlBadge component when status is "PASSED"', () => {
        expect(findGlBadge(wrapper).exists()).toBe(true);
        expect(findGlBadge(wrapper).text()).toBe('satisfied');
      });
    });
  });
});
