import { s__, __ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import GroupToken from './components/tokens/group_token.vue';
import MemberToken from './components/tokens/member_token.vue';
import ProjectToken from './components/tokens/project_token.vue';
import UserToken from './components/tokens/user_token.vue';

const DEFAULT_TOKEN_OPTIONS = {
  operators: OPERATOR_IS_ONLY,
  unique: true,
};

// Due to the i18n eslint rule we can't have a capitalized string even if it is a case-aware URL param
/* eslint-disable @gitlab/require-i18n-strings */
export const ENTITY_TYPES = {
  USER: 'User',
  AUTHOR: 'Author',
  GROUP: 'Group',
  PROJECT: 'Project',
};
/* eslint-enable @gitlab/require-i18n-strings */

export const AUDIT_FILTER_CONFIGS = [
  {
    ...DEFAULT_TOKEN_OPTIONS,
    icon: 'user',
    title: s__('AuditLogs|User Events'),
    type: 'user',
    entityType: ENTITY_TYPES.USER,
    token: UserToken,
  },
  {
    ...DEFAULT_TOKEN_OPTIONS,
    icon: 'user',
    title: s__('AuditLogs|Member Events'),
    type: 'member',
    entityType: ENTITY_TYPES.AUTHOR,
    token: MemberToken,
  },
  {
    ...DEFAULT_TOKEN_OPTIONS,
    icon: 'bookmark',
    title: s__('AuditLogs|Project Events'),
    type: 'project',
    entityType: ENTITY_TYPES.PROJECT,
    token: ProjectToken,
  },
  {
    ...DEFAULT_TOKEN_OPTIONS,
    icon: 'group',
    title: s__('AuditLogs|Group Events'),
    type: 'group',
    entityType: ENTITY_TYPES.GROUP,
    token: GroupToken,
  },
];

export const AVAILABLE_TOKEN_TYPES = AUDIT_FILTER_CONFIGS.map((token) => token.type);

export const MAX_DATE_RANGE = 31;

export const SAME_DAY_OFFSET = 1;

// This creates a date with zero time, making it simpler to match to the query date values
export const CURRENT_DATE = new Date(new Date().toDateString());

export const AUDIT_EVENTS_TAB_TITLES = {
  LOG: s__('AuditLogs|Log'),
  STREAM: s__('AuditStreams|Streams'),
};

export const ADD_STREAM = s__('AuditStreams|Add stream');
export const ACTIVE_STREAM = s__('AuditStreams|Active');
export const STREAM_COUNT_ICON_ALT = s__('AuditStreams|Stream count icon');
export const ADD_STREAM_MESSAGE = s__('AuditStreams|Stream added successfully');
export const UPDATE_STREAM_MESSAGE = s__('AuditStreams|Stream updated successfully');
export const DELETE_STREAM_MESSAGE = s__('AuditStreams|Stream deleted successfully');

export const STREAM_ITEMS_I18N = {
  VERIFICATION_TOKEN_TOOLTIP: s__('AuditStreams|Verification token'),
  EDIT_BUTTON_LABEL: s__('AuditStreams|Edit %{link}'),
  DELETE_BUTTON_LABEL: s__('AuditStreams|Delete %{link}'),
  EDIT_BUTTON_TOOLTIP: __('Edit'),
  DELETE_BUTTON_TOOLTIP: __('Delete'),
};

export const ADD_STREAM_EDITOR_I18N = {
  WARNING_TITLE: s__('AuditStreams|Destinations receive all audit event data'),
  WARNING_CONTENT: s__(
    'AuditStreams|This could include sensitive information. Make sure you trust the destination endpoint.',
  ),
  DESTINATION_URL_LABEL: s__('AuditStreams|Destination URL'),
  DESTINATION_URL_PLACEHOLDER: 'https://api.gitlab.com',
  HEADERS_LABEL: s__('AuditStreams|Custom HTTP headers'),
  TABLE_COLUMN_NAME_LABEL: s__('AuditStreams|Header'),
  TABLE_COLUMN_VALUE_LABEL: s__('AuditStreams|Value'),
  TABLE_COLUMN_ACTIVE_LABEL: s__('AuditStreams|Active'),
  HEADER_INPUT_PLACEHOLDER: s__('AuditStreams|Add a custom header'),
  HEADER_INPUT_DUPLICATE_ERROR: s__('AuditStreams|A header with this name already exists.'),
  VALUE_INPUT_PLACEHOLDER: s__('AuditStreams|Add a custom value'),
  MAXIMUM_HEADERS_TEXT: s__('AuditStreams|Maximum of %{number} HTTP headers has been reached.'),
  ADD_BUTTON_TEXT: __('Add'),
  ADD_BUTTON_NAME: s__('AuditStreams|Add external stream destination'),
  SAVE_BUTTON_TEXT: __('Save'),
  SAVE_BUTTON_NAME: s__('AuditStreams|Save external stream destination'),
  CANCEL_BUTTON_TEXT: __('Cancel'),
  CANCEL_BUTTON_NAME: s__('AuditStreams|Cancel editing'),
};

export const AUDIT_STREAMS_EMPTY_STATE_I18N = {
  TITLE: s__('AuditStreams|Setup streaming for audit events'),
  DESCRIPTION_1: s__(
    'AuditStreams|Add an HTTP endpoint to manage audit logs in third-party systems.',
  ),
  DESCRIPTION_2: s__('AuditStreams|This is great for keeping everything one place.'),
};

export const AUDIT_STREAMS_NETWORK_ERRORS = {
  FETCHING_ERROR: s__(
    'AuditStreams|An error occurred when fetching external audit event streams. Please try it again',
  ),
  CREATING_ERROR: s__(
    'AuditStreams|An error occurred when creating external audit event stream destination. Please try it again.',
  ),
  UPDATING_ERROR: s__(
    'AuditStreams|An error occurred when updating external audit event stream destination. Please try it again.',
  ),
  DELETING_ERROR: s__(
    'AuditStreams|An error occurred when deleting external audit event stream destination. Please try it again.',
  ),
};

export const MAX_HEADERS = 20;
export const createBlankHeader = () => ({
  id: null,
  name: '',
  value: '',
  active: true,
  disabled: false,
  deletionDisabled: true,
  validationErrors: { name: '' },
});
