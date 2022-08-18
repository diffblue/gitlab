import { gray500 } from '@gitlab/ui/scss_to_js/scss_variables';

export const LENGTH_ENUM = {
  hours: 'HOURS',
  days: 'DAYS',
  weeks: 'WEEKS',
};

export const CHEVRON_SKIPPING_SHADE_ENUM = ['500', '600', '700', '800', '900', '950'];

export const CHEVRON_SKIPPING_PALETTE_ENUM = ['blue', 'orange', 'aqua', 'green', 'magenta'];

export const LIGHT_TO_DARK_MODE_SHADE_MAPPING = {
  500: 500,
  600: 400,
  700: 300,
  800: 200,
  900: 100,
  950: 50,
};

export const ASSIGNEE_COLORS_COMBO = CHEVRON_SKIPPING_SHADE_ENUM.map((weight) =>
  CHEVRON_SKIPPING_PALETTE_ENUM.map((color) => ({
    colorWeight: weight,
    colorPalette: color,
  })),
).flat();

export const DAYS_IN_WEEK = 7;
export const HOURS_IN_DAY = 24;

export const PRESET_TYPES = {
  DAYS: 'DAYS',
  WEEKS: 'WEEKS',
};

export const PRESET_DEFAULTS = {
  WEEKS: {
    TIMEFRAME_LENGTH: 2,
  },
};

export const addRotationModalId = 'addRotationModal';
export const editRotationModalId = 'editRotationModal';
export const deleteRotationModalId = 'deleteRotationModal';

export const TIMELINE_CELL_WIDTH = 180;
export const SHIFT_WIDTH_CALCULATION_DELAY = 250;

export const oneHourOffsetDayView = 100 / HOURS_IN_DAY;
export const oneDayOffsetWeekView = 100 / DAYS_IN_WEEK;
export const oneHourOffsetWeekView = oneDayOffsetWeekView / HOURS_IN_DAY;

export const NON_ACTIVE_PARTICIPANT_STYLE = {
  colorWeight: '500',
  colorPalette: 'gray',
  textClass: 'gl-text-white',
  backgroundStyle: { backgroundColor: gray500 },
};
