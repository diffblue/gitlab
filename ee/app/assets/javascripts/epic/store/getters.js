import { parsePikadayDate } from '~/lib/utils/datetime_utility';

import { statusType } from '../constants';
import epicUtils from '../utils/epic_utils';

export const isEpicOpen = (state) => state.state === statusType.open;

export const isUserSignedIn = () => Boolean(gon.current_user_id);

export const startDateTime = (state) =>
  state.startDate ? parsePikadayDate(state.startDate) : null;

export const startDateTimeFixed = (state) =>
  state.startDateFixed ? parsePikadayDate(state.startDateFixed) : null;

export const startDateTimeFromMilestones = (state) =>
  state.startDateFromMilestones ? parsePikadayDate(state.startDateFromMilestones) : null;

export const dueDateTime = (state) => (state.dueDate ? parsePikadayDate(state.dueDate) : null);

export const dueDateTimeFixed = (state) =>
  state.dueDateFixed ? parsePikadayDate(state.dueDateFixed) : null;

export const dueDateTimeFromMilestones = (state) =>
  state.dueDateFromMilestones ? parsePikadayDate(state.dueDateFromMilestones) : null;

export const startDateForCollapsedSidebar = (state, getters) =>
  state.startDateIsFixed ? getters.startDateTime : getters.startDateTimeFromMilestones;

export const dueDateForCollapsedSidebar = (state, getters) =>
  state.dueDateIsFixed ? getters.dueDateTime : getters.dueDateTimeFromMilestones;

/**
 * This getter determines if epic dates
 * are valid (i.e. given start date is less than given due date)
 */
export const isDateInvalid = (state, getters) => {
  const { startDateIsFixed, dueDateIsFixed } = state;

  if (startDateIsFixed && dueDateIsFixed) {
    // When Epic start and finish dates are of type fixed.
    return !epicUtils.getDateValidity(getters.startDateTime, getters.dueDateTime);
  } else if (!startDateIsFixed && dueDateIsFixed) {
    // When Epic start date is from milestone and finish date is of type fixed.
    return !epicUtils.getDateValidity(getters.startDateTimeFromMilestones, getters.dueDateTime);
  } else if (startDateIsFixed && !dueDateIsFixed) {
    // When Epic start date is fixed and finish date is from milestone.
    return !epicUtils.getDateValidity(getters.startDateTime, getters.dueDateTimeFromMilestones);
  }

  // When both Epic start date and finish date are from milestone.
  return !epicUtils.getDateValidity(
    getters.startDateTimeFromMilestones,
    getters.dueDateTimeFromMilestones,
  );
};
