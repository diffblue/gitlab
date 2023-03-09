import { shallowMount } from '@vue/test-utils';
import mockTimezones from 'test_fixtures/timezones/full.json';
import DastScanSchedule from 'ee/security_configuration/dast_profiles/components/dast_scan_schedule.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('EE - DastScanSchedule', () => {
  let wrapper;

  const wrapperFactory = (mountFn = shallowMount) => (schedule) => {
    wrapper = mountFn(DastScanSchedule, {
      provide: {
        timezones: mockTimezones,
      },
      propsData: {
        schedule,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };
  const createComponent = wrapperFactory();

  it.each`
    description                | schedule
    ${'scan is not scheduled'} | ${null}
    ${'schedule is disabled'}  | ${{ active: false }}
  `(`renders '-' if $description`, ({ schedule }) => {
    createComponent(schedule);

    expect(wrapper.text()).toBe('-');
  });

  describe.each(['', {}, { unit: null, duration: null }])(
    'non-repeating schedule with cadence = %s',
    (cadence) => {
      const schedule = {
        active: true,
        cadence,
        startsAt: '2021-09-08T10:00:00+02:00',
        timezone: 'Europe/Paris',
      };

      beforeEach(() => {
        createComponent(schedule);
      });

      it('renders the run date', () => {
        expect(wrapper.text()).toBe('September 8, 2021');
      });

      it('attaches a tooltip with the run time', () => {
        const tooltip = getBinding(wrapper.element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe('10:00 AM CEST');
      });
    },
  );

  describe.each`
    unit       | duration | expectedText        | expectedTooltip
    ${'DAY'}   | ${1}     | ${'Every day'}      | ${'Every day at 10:00 AM CEST'}
    ${'WEEK'}  | ${1}     | ${'Every week'}     | ${'Every week on Wednesday at 10:00 AM CEST'}
    ${'MONTH'} | ${1}     | ${'Every month'}    | ${'Every month on the 8 at 10:00 AM CEST'}
    ${'MONTH'} | ${3}     | ${'Every 3 months'} | ${'Every 3 months on the 8 at 10:00 AM CEST'}
    ${'YEAR'}  | ${1}     | ${'Every year'}     | ${'Every year on September 8 at 10:00 AM CEST'}
  `(
    'repeating schedule ($expectedTooltip)',
    ({ unit, duration, expectedText, expectedTooltip }) => {
      const schedule = {
        active: true,
        cadence: { unit, duration },
        startsAt: '2021-09-08T10:00:00+02:00',
        timezone: 'Europe/Paris',
      };

      beforeEach(() => {
        createComponent(schedule);
      });

      it('renders the cadence text', () => {
        expect(wrapper.text()).toBe(expectedText);
      });

      it('attaches a tooltip with the recurrence details', () => {
        const tooltip = getBinding(wrapper.element, 'gl-tooltip');

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe(expectedTooltip);
      });
    },
  );

  describe('unknown timezone', () => {
    it("attaches a tooltip without the timezone's code", () => {
      createComponent({
        active: true,
        startsAt: '2021-09-08T10:00:00+02:00',
        timezone: 'TanukiLand/GitLabCity',
      });

      const tooltip = getBinding(wrapper.element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe('10:00 AM ');
    });
  });
});
