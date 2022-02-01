import { s__ } from '~/locale';

/*
  Update the counterparts in roadmap.scss when making changes.
*/

// Counterpart: $details-cell-width in roadmap.scss
export const EPIC_DETAILS_CELL_WIDTH = 320;

// Counterpart: $item-height in roadmap.scss
export const EPIC_ITEM_HEIGHT = 50;

// Counterpart: $timeline-cell-width in roadmap.scss
export const TIMELINE_CELL_MIN_WIDTH = 180;

export const SCROLL_BAR_SIZE = 16;

export const EPIC_HIGHLIGHT_REMOVE_AFTER = 3000;

export const DAYS_IN_WEEK = 7;

export const PERCENTAGE = 100;

export const SMALL_TIMELINE_BAR = 40;

export const DATE_RANGES = {
  CURRENT_QUARTER: 'CURRENT_QUARTER',
  CURRENT_YEAR: 'CURRENT_YEAR',
  THREE_YEARS: 'THREE_YEARS',
};

export const PRESET_TYPES = {
  QUARTERS: 'QUARTERS',
  MONTHS: 'MONTHS',
  WEEKS: 'WEEKS',
};

export const EPICS_STATES = {
  ALL: 'all',
  OPENED: 'opened',
  CLOSED: 'closed',
};

export const emptyStateDefault = s__(
  'GroupRoadmap|To view the roadmap, add a start or due date to one of your epics in this group or its subgroups; from %{startDate} to %{endDate}.',
);

export const emptyStateWithFilters = s__(
  'GroupRoadmap|To widen your search, change or remove filters; from %{startDate} to %{endDate}.',
);

export const emptyStateWithEpicIidFiltered = s__(
  'GroupRoadmap|To make your epics appear in the roadmap, add start or due dates to them.',
);

export const EPIC_LEVEL_MARGIN = {
  1: 'ml-4',
  2: 'ml-6',
  3: 'ml-8',
  4: 'ml-10',
};

export const ROADMAP_PAGE_SIZE = 50;

export const PROGRESS_TRACKING_OPTIONS = {
  WEIGHT: 'WEIGHT',
  COUNT: 'COUNT',
};
