import { pickBy, isNull, isNaN } from 'lodash';
import { formatParticipantsForTokenSelector } from 'ee/oncall_schedules/utils/common_utils';
import { EMAIL_ONCALL_SCHEDULE_USER, EMAIL_USER } from './constants';

/**
 * Returns `true` for non-empty string, otherwise returns `false`
 * @param {String} name
 *
 * @returns {Boolean}
 */
export const isNameFieldValid = (name) => {
  return Boolean(name?.length);
};

/**
 * Returns an array of booleans  - validation state for each rule
 * @param {Array} rules
 *
 * @returns {Array}
 */
export const getRulesValidationState = (rules) => {
  return rules.map(({ elapsedTimeMinutes, oncallScheduleIid, username, action }) => {
    const minutes = parseInt(elapsedTimeMinutes, 10);
    return {
      isTimeValid: minutes >= 0 && minutes <= 1440,
      isScheduleValid: action === EMAIL_ONCALL_SCHEDULE_USER ? Boolean(oncallScheduleIid) : true,
      isUserValid: action === EMAIL_USER ? Boolean(username) : true,
    };
  });
};

/**
 * Serializes a rule by converting elapsed minutes to seconds
 * @param {Object} rule
 *
 * @returns {Object} rule
 */
export const serializeRule = ({ elapsedTimeMinutes, ...ruleParams }) => {
  const params = { ...ruleParams };
  delete params.action;
  return {
    ...params,
    elapsedTimeSeconds: elapsedTimeMinutes * 60,
  };
};

/**
 * Parses a policy by converting elapsed seconds to minutes
 * @param {Object} policy
 *
 * @returns {Object} policy
 */
export const parsePolicy = (policy) => ({
  ...policy,
  rules: policy.rules.map(({ elapsedTimeSeconds, ...ruleParams }) => ({
    ...ruleParams,
    elapsedTimeMinutes: elapsedTimeSeconds / 60,
  })),
});

/**
 * Parses a rule for the UI form usage or doe BE params serializing
 * @param {Array} of transformed rules from BE
 *
 * @returns {Array} of rules
 */
export const getRules = (rules) => {
  return rules.map(
    ({ status, elapsedTimeMinutes, oncallScheduleIid, oncallSchedule, user, username }) => {
      const actionBasedProps = pickBy(
        {
          username: username ?? user?.username,
          oncallScheduleIid: parseInt(oncallScheduleIid ?? oncallSchedule?.iid, 10),
        },
        (prop) => !(isNull(prop) || isNaN(prop)),
      );

      return {
        status,
        elapsedTimeMinutes,
        ...actionBasedProps,
      };
    },
  );
};

/**
 * Mapps participants of policy and assign token styles
 * @param {Array} rules
 *
 * @returns {Array}
 */
export const getParticipantsWithTokenStyles = (rules) => {
  const participants = rules
    .filter((rule) => rule.user || rule.username)
    .map((rule, index) => ({ username: rule.user ? rule.user.username : rule.username, index }));

  return formatParticipantsForTokenSelector(participants);
};

/**
 * Finds user's index within the view of all escalation rules
 * @param {Array} mappedParticipants
 * @param {string} username
 *
 * @returns {Number}
 */
export const getEscalationUserIndex = (mappedParticipants, username) =>
  mappedParticipants.findIndex((participant) => participant.username === username);
