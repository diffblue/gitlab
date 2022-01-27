import $ from 'jquery';
import { getCookie, setCookie, parseBoolean } from '~/lib/utils/common_utils';

import { sanitize } from '~/lib/dompurify';
import createGqClient, { fetchPolicies } from '~/lib/graphql';

import { dateInWords, parsePikadayDate } from '~/lib/utils/datetime_utility';
import { __, s__, sprintf } from '~/locale';

import { dateTypes } from '../constants';

const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);

const triggerDocumentEvent = (eventName, eventParam) => {
  $(document).trigger(eventName, eventParam);
};

const bindDocumentEvent = (eventName, callback) => {
  $(document).on(eventName, callback);
};

const toggleContainerClass = (className) => {
  const containerEl = document.querySelector('.page-with-contextual-sidebar');

  if (containerEl) {
    containerEl.classList.toggle(className);
  }
};

const getCollapsedGutter = () => parseBoolean(getCookie('collapsed_gutter'));

const setCollapsedGutter = (value) => setCookie('collapsed_gutter', value);

const getDateValidity = (startDateTime, dueDateTime) => {
  // If both dates are defined
  // only then compare, return true otherwise
  if (startDateTime && dueDateTime) {
    return startDateTime.getTime() < dueDateTime.getTime();
  }
  return true;
};

const getDateFromMilestonesTooltip = ({
  dateType = dateTypes.start,
  startDateSourcingMilestoneTitle,
  startDateSourcingMilestoneDates,
  startDateTimeFromMilestones,
  dueDateSourcingMilestoneTitle,
  dueDateSourcingMilestoneDates,
  dueDateTimeFromMilestones,
}) => {
  const dateSourcingMilestoneTitle = sanitize(
    dateType === dateTypes.start ? startDateSourcingMilestoneTitle : dueDateSourcingMilestoneTitle,
  );
  const sourcingMilestoneDates =
    dateType === dateTypes.start ? startDateSourcingMilestoneDates : dueDateSourcingMilestoneDates;

  if (startDateTimeFromMilestones && dueDateTimeFromMilestones) {
    const { startDate, dueDate } = sourcingMilestoneDates;
    let startDateInWords = __('No start date');
    let dueDateInWords = __('No due date');

    if (startDate && dueDate) {
      const startDateObj = parsePikadayDate(startDate);
      const dueDateObj = parsePikadayDate(dueDate);
      startDateInWords = dateInWords(
        startDateObj,
        true,
        startDateObj.getFullYear() === dueDateObj.getFullYear(),
      );
      dueDateInWords = dateInWords(dueDateObj, true);
    } else if (startDate && !dueDate) {
      startDateInWords = dateInWords(parsePikadayDate(startDate), true);
    } else {
      dueDateInWords = dateInWords(parsePikadayDate(dueDate), true);
    }

    return `${dateSourcingMilestoneTitle}<br/><span class="text-tertiary">${startDateInWords} – ${dueDateInWords}</span>`;
  }

  return sprintf(
    s__(
      "Epics|To schedule your epic's %{epicDateType} date based on milestones, assign a milestone with a %{epicDateType} date to any issue in the epic.",
    ),
    {
      epicDateType: dateTypes.start === dateType ? s__('Epics|start') : s__('Epics|due'),
    },
  );
};

const epicUtils = {
  gqClient,
  triggerDocumentEvent,
  bindDocumentEvent,
  toggleContainerClass,
  getCollapsedGutter,
  setCollapsedGutter,
  getDateValidity,
  getDateFromMilestonesTooltip,
};

export default epicUtils;
