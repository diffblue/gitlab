import { s__, __ } from '~/locale';

export const FEATURE_PRODUCT_ANALYTICS = 'productAnalytics';

export const PRODUCT_ANALYTICS_FEATURE_DASHBOARDS = ['audience', 'behavior'];

export const I18N_NEW_DASHBOARD_BREADCRUMB = s__('Analytics|New dashboard');

export const I18N_BUILT_IN_DASHBOARD_LABEL = s__('Analytics|By GitLab');

export const I18N_DASHBOARD_LIST_TITLE = s__('Analytics|Analytics dashboards');
export const I18N_DASHBOARD_LIST_TITLE_BREADCRUMB = s__('Analytics|Analytics dashboards');
export const I18N_DASHBOARD_LIST_PROJECT_DESCRIPTION = s__(
  'Analytics|Dashboards are created by editing the projects dashboard files.',
);
export const I18N_DASHBOARD_LIST_GROUP_DESCRIPTION = s__(
  'Analytics|Dashboards are created by editing the groups dashboard files.',
);
export const I18N_DASHBOARD_LIST_LEARN_MORE = __('Learn more.');
export const I18N_DASHBOARD_LIST_NEW_DASHBOARD = s__('Analytics|New dashboard');
export const I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER = s__('Analytics|Visualization Designer');
export const I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER_BREADCRUMB = s__(
  'Analytics|Visualization designer',
);
export const I18N_DASHBOARD_LIST_VISUALIZATION_DESIGNER_CUBEJS_ERROR = s__(
  'Analytics|An error occurred while loading data',
);

export const I18N_DASHBOARD_VISUALIZATION_DESIGNER_NAME_ERROR = s__(
  'Analytics|Enter a visualization name',
);
export const I18N_DASHBOARD_VISUALIZATION_DESIGNER_MEASURE_ERROR = s__(
  'Analytics|Select a measurement',
);
export const I18N_DASHBOARD_VISUALIZATION_DESIGNER_TYPE_ERROR = s__(
  'Analytics|Select a visualization type',
);
export const I18N_DASHBOARD_VISUALIZATION_DESIGNER_ALREADY_EXISTS_ERROR = s__(
  'Analytics|A visualization with that name already exists.',
);
export const I18N_DASHBOARD_VISUALIZATION_DESIGNER_SAVE_ERROR = s__(
  'Analytics|Error while saving visualization.',
);
export const I18N_DASHBOARD_VISUALIZATION_DESIGNER_SAVE_SUCCESS = s__(
  'Analytics|Visualization was saved successfully',
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

export const EVENTS_TABLE_NAME = 'SnowplowTrackedEvents';
export const SESSIONS_TABLE_NAME = 'SnowplowSessions';

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
    dbField: 'pageUrl',
    icon: 'documents',
  },
  {
    name: s__('Analytics|Page Path'),
    category: 'pages',
    dbField: 'pageUrlpath',
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
    dbField: 'documentLanguage',
    icon: 'documents',
  },
  {
    name: s__('Analytics|Host'),
    category: 'pages',
    dbField: 'pageUrlhosts',
    icon: 'documents',
  },
  {
    name: s__('Analytics|Referer'),
    category: 'users',
    dbField: 'pageReferrer',
    icon: 'user',
  },
  {
    name: s__('Analytics|Language'),
    category: 'users',
    dbField: 'browserLanguage',
    icon: 'user',
  },
  {
    name: s__('Analytics|Viewport'),
    category: 'users',
    dbField: 'viewportSize',
    icon: 'user',
  },
  {
    name: s__('Analytics|Browser Family'),
    category: 'users',
    dbField: 'agentName',
    icon: 'user',
  },
  {
    name: s__('Analytics|Browser'),
    category: 'users',
    dbField: ['agentName', 'agentVersion'],
    icon: 'user',
  },
  {
    name: s__('Analytics|OS'),
    category: 'users',
    dbField: 'osName',
    icon: 'user',
  },
  {
    name: s__('Analytics|OS Version'),
    category: 'users',
    dbField: ['osName', 'osVersion'],
    icon: 'user',
  },
];

export const NEW_DASHBOARD = () => ({
  title: s__('Analytics|New dashboard'),
  panels: [],
  userDefined: true,
});

export const I18N_PRODUCT_ANALYTICS_TITLE = __('Product analytics');
