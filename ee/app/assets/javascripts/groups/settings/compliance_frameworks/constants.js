import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, s__ } from '~/locale';

export const DANGER = 'danger';
export const INFO = 'info';

export const FETCH_ERROR = s__(
  'ComplianceFrameworks|Error fetching compliance frameworks data. Please refresh the page or try a different framework',
);
export const SAVE_ERROR = s__(
  'ComplianceFrameworks|Unable to save this compliance framework. Please try again',
);

export const OPTIONS_BUTTON_LABEL = __('Options');
export const EDIT_BUTTON_LABEL = s__('ComplianceFrameworks|Edit framework');
export const DELETE_BUTTON_LABEL = s__('ComplianceFrameworks|Delete framework');
export const SET_DEFAULT_BUTTON_LABEL = s__('ComplianceFrameworks|Set default');
export const REMOVE_DEFAULT_BUTTON_LABEL = s__('ComplianceFrameworks|Remove default');

export const EDIT_PATH_ID_FORMAT = /\/id\//;

// Check that it matches the format [FILE].y(a)ml@[GROUP]/[PROJECT]
export const PIPELINE_CONFIGURATION_PATH_FORMAT = /^([^@]*\.ya?ml)@([^/]*)\/(.*)$/;

export const DEBOUNCE_DELAY = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;
