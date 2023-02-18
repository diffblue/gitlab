import {
  MIN_NUM_REPOS,
  MAX_NUM_REPOS,
  NUM_REPOS_BLANK_ERROR,
  NUM_REPOS_NAN_ERROR,
  NUM_REPOS_LIMIT_ERROR,
  MIN_TIME_PERIOD,
  MAX_TIME_PERIOD,
  TIME_PERIOD_BLANK_ERROR,
  TIME_PERIOD_NAN_ERROR,
  TIME_PERIOD_LIMIT_ERROR,
  MAX_ALLOWED_USERS,
  ALLOWED_USERS_LIMIT_ERROR,
  MIN_ALERTED_USERS,
  MAX_ALERTED_USERS,
  ALERTED_USERS_LIMIT_ERROR,
} from './constants';

export const validateNumberOfRepos = (data) => {
  if (!data && data !== 0) {
    return NUM_REPOS_BLANK_ERROR;
  }

  if (data && Number.isNaN(Number(data))) {
    return NUM_REPOS_NAN_ERROR;
  }

  if (data < MIN_NUM_REPOS || data > MAX_NUM_REPOS) {
    return NUM_REPOS_LIMIT_ERROR;
  }

  return '';
};

export const validateReportingTimePeriod = (data) => {
  if (!data && data !== 0) {
    return TIME_PERIOD_BLANK_ERROR;
  }

  if (data && Number.isNaN(Number(data))) {
    return TIME_PERIOD_NAN_ERROR;
  }

  if (data < MIN_TIME_PERIOD || data > MAX_TIME_PERIOD) {
    return TIME_PERIOD_LIMIT_ERROR;
  }

  return '';
};

export const validateAllowedUsers = (data) => {
  if (data.length > MAX_ALLOWED_USERS) {
    return ALLOWED_USERS_LIMIT_ERROR;
  }

  return '';
};

export const validateAlertedUsers = (data) => {
  if (data.length < MIN_ALERTED_USERS || data.length > MAX_ALERTED_USERS) {
    return ALERTED_USERS_LIMIT_ERROR;
  }

  return '';
};
