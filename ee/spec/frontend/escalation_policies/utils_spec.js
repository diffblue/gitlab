import { EMAIL_ONCALL_SCHEDULE_USER, EMAIL_USER } from 'ee/escalation_policies/constants';
import * as utils from 'ee/escalation_policies/utils';

const userObject = { username: 'user2' };
const rulesMock = [
  { elapsedTimeMinutes: 0, status: 'Resolved', oncallScheduleId: null, username: 'user' },
  { elapsedTimeMinutes: 20, status: 'Resolved', oncallSchedule: { iid: '2' }, username: null },
  { elapsedTimeMinutes: 40, status: 'Resolved', oncallScheduleId: null, user: userObject },
];
const participantsWithTokenStyles = utils.getParticipantsWithTokenStyles(rulesMock);

describe('Escalation policies utility functions', () => {
  describe('isNameFieldValid', () => {
    it('should return `true` when name is valid', () => {
      expect(utils.isNameFieldValid('policy name')).toBe(true);
    });

    it('should return `false` otherwise', () => {
      expect(utils.isNameFieldValid('')).toBe(false);
      expect(utils.isNameFieldValid(undefined)).toBe(false);
    });
  });

  describe('getRulesValidationState', () => {
    it.each`
      rules                                                                                                          | validationState
      ${[{ elapsedTimeMinutes: 10, oncallScheduleIid: 1, username: null, action: EMAIL_ONCALL_SCHEDULE_USER }]}      | ${[{ isTimeValid: true, isScheduleValid: true, isUserValid: true }]}
      ${[{ elapsedTimeMinutes: 1500, oncallScheduleIid: 1, username: null, action: EMAIL_ONCALL_SCHEDULE_USER }]}    | ${[{ isTimeValid: false, isScheduleValid: true, isUserValid: true }]}
      ${[{ elapsedTimeMinutes: -2, oncallScheduleIid: null, username: 'user', action: EMAIL_ONCALL_SCHEDULE_USER }]} | ${[{ isTimeValid: false, isScheduleValid: false, isUserValid: true }]}
      ${[{ elapsedTimeMinutes: 30, oncallScheduleIid: null, username: 'user', action: EMAIL_USER }]}                 | ${[{ isTimeValid: true, isScheduleValid: true, isUserValid: true }]}
      ${[{ elapsedTimeMinutes: 30, oncallScheduleIid: 1, username: null, action: EMAIL_USER }]}                      | ${[{ isTimeValid: true, isScheduleValid: true, isUserValid: false }]}
    `('calculates rules validation state', ({ rules, validationState }) => {
      expect(utils.getRulesValidationState(rules)).toEqual(validationState);
    });
  });

  describe('parsePolicy', () => {
    it('parses a policy by converting elapsed seconds to minutes for ecach rule', () => {
      const policy = {
        name: 'policy',
        rules: [
          { elapsedTimeSeconds: 600, username: 'user' },
          { elapsedTimeSeconds: 0, oncallScheduleIid: 1 },
        ],
      };
      expect(utils.parsePolicy(policy)).toEqual({
        name: 'policy',
        rules: [
          { elapsedTimeMinutes: 10, username: 'user' },
          { elapsedTimeMinutes: 0, oncallScheduleIid: 1 },
        ],
      });
    });
  });

  describe('getRules', () => {
    it.each`
      rules                                                                                                    | transformedRules
      ${[{ elapsedTimeMinutes: 10, status: 'Acknowledged', oncallScheduleIid: '1', username: null }]}          | ${[{ elapsedTimeMinutes: 10, status: 'Acknowledged', oncallScheduleIid: 1 }]}
      ${[{ elapsedTimeMinutes: 20, status: 'Resolved', oncallSchedule: { iid: '2' }, username: null }]}        | ${[{ elapsedTimeMinutes: 20, status: 'Resolved', oncallScheduleIid: 2 }]}
      ${[{ elapsedTimeMinutes: 0, status: 'Resolved', oncallScheduleId: null, username: 'user' }]}             | ${[{ elapsedTimeMinutes: 0, status: 'Resolved', username: 'user' }]}
      ${[{ elapsedTimeMinutes: 40, status: 'Resolved', oncallScheduleId: null, user: { username: 'user2' } }]} | ${[{ elapsedTimeMinutes: 40, status: 'Resolved', username: 'user2' }]}
    `('transforms the rules', ({ rules, transformedRules }) => {
      expect(utils.getRules(rules)).toEqual(transformedRules);
    });
  });

  describe('getParticipantsWithTokenStyles', () => {
    it('retrieves all participants from escalation rules and assigns them token styles', () => {
      const expectedStyles = [
        {
          class: 'gl-text-white',
          style: { backgroundColor: '#617ae2' },
        },
        {
          class: 'gl-text-white',
          style: { backgroundColor: '#c95d2e' },
        },
      ];

      expect(participantsWithTokenStyles.length).toBe(
        rulesMock.filter((rule) => rule.user || rule.username).length,
      );
      participantsWithTokenStyles.forEach((participant, index) => {
        expect(participant.style).toEqual(expectedStyles[index].style);
        expect(participant.class).toBe(expectedStyles[index].class);
      });
    });
  });

  describe('getEscalationUserIndex', () => {
    it('finds user index in mappedParticipants array', () => {
      expect(utils.getEscalationUserIndex(participantsWithTokenStyles, userObject.username)).toBe(
        1,
      );
    });
  });
});
