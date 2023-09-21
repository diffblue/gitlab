import { s__ } from '~/locale';

export const FEATURE_PRODUCT_ANALYTICS = 'productAnalytics';

export const PRODUCT_ANALYTICS_FEATURE_DASHBOARDS = ['audience', 'behavior'];

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

export const EVENTS_TABLE_NAME = 'TrackedEvents';
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
  title: '',
  description: '',
  panels: [],
  userDefined: true,
});
