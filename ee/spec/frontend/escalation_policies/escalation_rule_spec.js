import { GlDropdownItem, GlFormGroup, GlSprintf } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import EscalationRule, { i18n } from 'ee/escalation_policies/components/escalation_rule.vue';
import UserSelect from 'ee/escalation_policies/components/user_select.vue';
import {
  DEFAULT_ESCALATION_RULE,
  ACTIONS,
  ALERT_STATUSES,
  EMAIL_ONCALL_SCHEDULE_USER,
  EMAIL_USER,
} from 'ee/escalation_policies/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

const mockSchedules = [
  { id: 1, name: 'schedule1' },
  { id: 2, name: 'schedule2' },
  { id: 3, name: 'schedule3' },
];

const emptyScheduleMsg = i18n.fields.rules.emptyScheduleValidationMsg;
const noUserSelecteddErrorMsg = i18n.fields.rules.invalidUserValidationMsg;
const invalidTimeMsg = i18n.fields.rules.invalidTimeValidationMsg;

describe('EscalationRule', () => {
  let wrapper;
  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(EscalationRule, {
      propsData: {
        rule: cloneDeep(DEFAULT_ESCALATION_RULE),
        schedules: mockSchedules,
        schedulesLoading: false,
        mappedParticipants: [],
        index: 0,
        isValid: false,
        ...props,
      },
      stubs: {
        GlFormGroup,
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findStatusDropdown = () => wrapper.findByTestId('alert-status-dropdown');
  const findStatusDropdownOptions = () => findStatusDropdown().findAllComponents(GlDropdownItem);

  const findActionDropdown = () => wrapper.findByTestId('action-dropdown');
  const findActionDropdownOptions = () => findActionDropdown().findAllComponents(GlDropdownItem);

  const findSchedulesDropdown = () => wrapper.findByTestId('schedules-dropdown');
  const findSchedulesDropdownOptions = () =>
    findSchedulesDropdown().findAllComponents(GlDropdownItem);
  const findUserSelect = () => wrapper.findComponent(UserSelect);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);

  const findNoSchedulesInfoIcon = () => wrapper.findByTestId('no-schedules-info-icon');

  describe('Status dropdown', () => {
    it('should have correct alert status options', () => {
      expect(findStatusDropdownOptions().wrappers.map((w) => w.text())).toStrictEqual(
        Object.values(ALERT_STATUSES),
      );
    });

    it('should have default status selected', () => {
      expect(findStatusDropdownOptions().at(0).props('isChecked')).toBe(true);
    });
  });

  describe('Actions dropdown', () => {
    it('should have correct action options', () => {
      expect(findActionDropdownOptions().wrappers.map((w) => w.text())).toStrictEqual(
        Object.values(ACTIONS),
      );
    });

    it('should have default action selected', () => {
      expect(findActionDropdownOptions().at(0).props('isChecked')).toBe(true);
    });
  });

  describe('Schedules dropdown', () => {
    it('should have correct schedules options', () => {
      expect(findSchedulesDropdownOptions().wrappers.map((w) => w.text())).toStrictEqual(
        mockSchedules.map(({ name }) => name),
      );
    });

    it('should NOT disable the dropdown OR show the info icon when schedules are loaded and provided', () => {
      expect(findSchedulesDropdown().attributes('disabled')).toBeUndefined();
      expect(findNoSchedulesInfoIcon().exists()).toBe(false);
    });

    it('should disable the dropdown and show the info icon when no schedules provided', () => {
      createComponent({ props: { schedules: [], schedulesLoading: false } });
      expect(findSchedulesDropdown().attributes('disabled')).toBeDefined();
      expect(findNoSchedulesInfoIcon().exists()).toBe(true);
    });

    it('should not render UserSelect when action is EMAIL_ONCALL_SCHEDULE_USER', () => {
      createComponent({
        props: {
          rule: {
            ...DEFAULT_ESCALATION_RULE,
            action: EMAIL_ONCALL_SCHEDULE_USER,
          },
        },
      });
      expect(findUserSelect().exists()).toBe(false);
    });
  });

  describe('User select', () => {
    beforeEach(() => {
      createComponent({
        props: {
          rule: {
            ...DEFAULT_ESCALATION_RULE,
            action: EMAIL_USER,
          },
        },
      });
    });

    it('should render UserSelect when action is EMAIL USER', () => {
      expect(findUserSelect().exists()).toBe(true);
    });

    it('should NOT render schedule selection dropdown when action is EMAIL USER', () => {
      expect(findSchedulesDropdown().exists()).toBe(false);
    });
  });

  describe('Validation', () => {
    describe.each`
      validationState                                                      | formState    | action
      ${{ isTimeValid: true, isScheduleValid: true, isUserValid: true }}   | ${'true'}    | ${EMAIL_ONCALL_SCHEDULE_USER}
      ${{ isTimeValid: false, isScheduleValid: true, isUserValid: true }}  | ${undefined} | ${EMAIL_ONCALL_SCHEDULE_USER}
      ${{ isTimeValid: true, isScheduleValid: false, isUserValid: true }}  | ${undefined} | ${EMAIL_ONCALL_SCHEDULE_USER}
      ${{ isTimeValid: true, isScheduleValid: true, isUserValid: false }}  | ${undefined} | ${EMAIL_USER}
      ${{ isTimeValid: false, isScheduleValid: false, isUserValid: true }} | ${undefined} | ${EMAIL_ONCALL_SCHEDULE_USER}
      ${{ isTimeValid: false, isScheduleValid: true, isUserValid: false }} | ${undefined} | ${EMAIL_USER}
    `(`when`, ({ validationState, formState, action }) => {
      describe(`elapsed minutes control is ${
        validationState.isTimeValid ? 'valid' : 'invalid'
      } and schedule control is ${
        validationState.isScheduleValid ? 'valid' : 'invalid'
      } and user control is ${validationState.isUserValid ? 'valid' : 'invalid'}`, () => {
        beforeEach(() => {
          createComponent({
            props: {
              validationState,
              rule: {
                ...DEFAULT_ESCALATION_RULE,
                action,
              },
            },
          });

          wrapper.vm.$el.dispatchEvent(new Event('focusout'));
        });

        it(`sets form group validation state to ${formState}`, () => {
          expect(findFormGroup().attributes('state')).toBe(formState);
        });

        it(`does ${
          validationState.isTimeValid ? 'not show' : 'show'
        } invalid time error message && does ${
          validationState.isScheduleValid ? 'not show' : 'show'
        } no schedule error message && does ${
          validationState.isUserValid ? 'not show' : 'show'
        } no user error message `, () => {
          if (validationState.isTimeValid) {
            expect(findFormGroup().text()).not.toContain(invalidTimeMsg);
          } else {
            expect(findFormGroup().text()).toContain(invalidTimeMsg);
          }

          if (validationState.isScheduleValid) {
            expect(findFormGroup().text()).not.toContain(emptyScheduleMsg);
          } else {
            expect(findFormGroup().text()).toContain(emptyScheduleMsg);
          }

          if (validationState.isUserValid) {
            expect(findFormGroup().text()).not.toContain(noUserSelecteddErrorMsg);
          } else {
            expect(findFormGroup().text()).toContain(noUserSelecteddErrorMsg);
          }
        });
      });
    });
  });
});
