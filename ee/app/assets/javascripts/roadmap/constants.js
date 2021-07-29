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

export const EXTEND_AS = {
  PREPEND: 'prepend',
  APPEND: 'append',
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

export const PRESET_DEFAULTS = {
  QUARTERS: {
    TIMEFRAME_LENGTH: 21,
  },
  MONTHS: {
    TIMEFRAME_LENGTH: 8,
  },
  WEEKS: {
    TIMEFRAME_LENGTH: 7,
  },
};

export const EPIC_LEVEL_MARGIN = {
  1: 'ml-4',
  2: 'ml-6',
  3: 'ml-8',
  4: 'ml-10',
};

export const EPICS_LIMIT_DISMISSED_COOKIE_NAME = 'epics_limit_warning_dismissed';

export const EPICS_LIMIT_DISMISSED_COOKIE_TIMEOUT = 365;

export const ROADMAP_PAGE_SIZE = gon.features?.performanceRoadmap ? 50 : gon.roadmap_epics_limit;
