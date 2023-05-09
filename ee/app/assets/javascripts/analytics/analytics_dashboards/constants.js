import { s__, __ } from '~/locale';

export const I18N_DASHBOARD_LIST_TITLE = s__('Analytics|Analytics dashboards');
export const I18N_DASHBOARD_LIST_DESCRIPTION = s__(
  'Analytics|Dashboards are created by editing the projects dashboard files.',
);
export const I18N_DASHBOARD_LIST_LEARN_MORE = __('Learn more.');
export const I18N_DASHBOARD_LIST_NEW_DASHBOARD = s__('Analytics|New dashboard');
export const I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER = s__('Analytics|Visualization Designer');
export const I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER_CUBEJS_ERROR = s__(
  'Analytics|An error occurred while loading data',
);

export const I18N_ALERT_NO_POINTER_TITLE = s__('Analytics|Custom dashboards');
export const I18N_ALERT_NO_POINTER_BUTTON = s__('Analytics|Configure Dashboard Project');
export const I18N_ALERT_NO_POINTER_DESCRIPTION = s__(
  'Analytics|To create your own dashboards, first configure a project to store your dashboards.',
);

export const I18N_DASHBOARD_NOT_FOUND_TITLE = s__('Analytics|Dashboard not found');
export const I18N_DASHBOARD_NOT_FOUND_DESCRIPTION = s__(
  'Analytics|No dashboard matches the specified URL path.',
);
export const I18N_DASHBOARD_NOT_FOUND_ACTION = s__('Analytics|View available dashboards');

export const I18N_DASHBOARD_SAVED_SUCCESSFULLY = s__('Analytics|Dashboard was saved successfully');
export const I18N_DASHBOARD_ERROR_WHILE_SAVING = s__('Analytics|Error while saving dashboard');

export const VISUALIZATION_TYPE_FILE = 'yml';
export const VISUALIZATION_TYPE_BUILT_IN = 'builtin';

export const EVENTS_TYPES = ['pageViews', 'featureUsages', 'clickEvents', 'events'];

export function isTrackedEvent(eventType) {
  return EVENTS_TYPES.includes(eventType);
}

export const PANEL_VISUALIZATION_HEIGHT = '600px';

export const PANEL_DISPLAY_TYPES = {
  DATA: 'data',
  VISUALIZATION: 'visualization',
  CODE: 'code',
};

export const PANEL_DISPLAY_TYPE_ITEMS = [
  {
    type: PANEL_DISPLAY_TYPES.DATA,
    icon: 'table',
    title: s__('Analytics|Data'),
  },
  {
    type: PANEL_DISPLAY_TYPES.VISUALIZATION,
    icon: 'chart',
    title: s__('Analytics|Visualization'),
  },
  {
    type: PANEL_DISPLAY_TYPES.CODE,
    icon: 'code',
    title: s__('Analytics|Code'),
  },
];

export const MEASURE_COLOR = '#00b140';
export const DIMENSION_COLOR = '#c3e6cd';

export const EVENTS_DB_TABLE_NAME = 'TrackedEvents';
export const SESSIONS_TABLE_NAME = 'Sessions';

export const ANALYTICS_FIELD_CATEGORIES = [
  {
    name: s__('Analytics|Pages'),
    category: 'pages',
  },
  {
    name: s__('Analytics|Users'),
    category: 'users',
  },
];

export const ANALYTICS_FIELDS = [
  {
    name: s__('Analytics|URL'),
    category: 'pages',
    dbField: 'url',
    icon: 'documents',
  },
  {
    name: s__('Analytics|Page Path'),
    category: 'pages',
    dbField: 'docPath',
    icon: 'documents',
  },
  {
    name: s__('Analytics|Page Title'),
    category: 'pages',
    dbField: 'pageTitle',
    icon: 'documents',
  },
  {
    name: s__('Analytics|Page Language'),
    category: 'pages',
    dbField: 'docEncoding',
    icon: 'documents',
  },
  {
    name: s__('Analytics|Host'),
    category: 'pages',
    dbField: 'docHost',
    icon: 'documents',
  },
  {
    name: s__('Analytics|Referer'),
    category: 'users',
    dbField: 'referer',
    icon: 'user',
  },
  {
    name: s__('Analytics|Language'),
    category: 'users',
    dbField: 'userLanguage',
    icon: 'user',
  },
  {
    name: s__('Analytics|Viewport'),
    category: 'users',
    dbField: 'vpSize',
    icon: 'user',
  },
  {
    name: s__('Analytics|Browser Family'),
    category: 'users',
    dbField: 'parsedUaUaFamily',
    icon: 'user',
  },
  {
    name: s__('Analytics|Browser'),
    category: 'users',
    dbField: ['parsedUaUaFamily', 'parsedUaUaVersion'],
    icon: 'user',
  },
  {
    name: s__('Analytics|OS'),
    category: 'users',
    dbField: 'parsedUaOsFamily',
    icon: 'user',
  },
  {
    name: s__('Analytics|OS Version'),
    category: 'users',
    dbField: ['parsedUaOsFamily', 'parsedUaOsVersion'],
    icon: 'user',
  },
];

export const NEW_DASHBOARD = {
  title: s__('Analytics|New dashboard'),
  panels: [],
};
