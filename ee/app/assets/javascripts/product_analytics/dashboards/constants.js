import { s__, __ } from '~/locale';

export const I18N_DASHBOARD_LIST = {
  title: s__('ProductAnalytics|Product analytics dashboards'),
  description: s__(
    'ProductAnalytics|Dashboards are created by editing the projects dashboard files.',
  ),
  learnMore: __('Learn more.'),
};

export const EVENTS_TYPES = ['pageViews', 'featureUsages', 'clickEvents', 'events'];

export const WIDGET_DISPLAY_TYPES = {
  DATA: 'data',
  WIDGET: 'widget',
  CODE: 'code',
};

export const WIDGET_DISPLAY_TYPE_ITEMS = [
  {
    type: WIDGET_DISPLAY_TYPES.DATA,
    icon: 'table',
    title: s__('ProductAnalytics|Data'),
  },
  {
    type: WIDGET_DISPLAY_TYPES.WIDGET,
    icon: 'chart',
    title: s__('ProductAnalytics|Widget'),
  },
  {
    type: WIDGET_DISPLAY_TYPES.CODE,
    icon: 'code',
    title: s__('ProductAnalytics|Code'),
  },
];

export const MEASURE_COLOR = '#00b140';
export const DIMENSION_COLOR = '#c3e6cd';

export const EVENTS_DB_TABLE_NAME = 'Jitsu';

export const ANALYTICS_FIELD_CATEGORIES = [
  {
    name: s__('ProductAnalytics|Pages'),
    category: 'pages',
  },
  {
    name: s__('ProductAnalytics|Users'),
    category: 'users',
  },
];

export const ANALYTICS_FIELDS = [
  {
    name: s__('ProductAnalytics|URL'),
    category: 'pages',
    dbField: 'url',
    icon: 'documents',
  },
  {
    name: s__('ProductAnalytics|Page Path'),
    category: 'pages',
    dbField: 'docPath',
    icon: 'documents',
  },
  {
    name: s__('ProductAnalytics|Page Title'),
    category: 'pages',
    dbField: 'pageTitle',
    icon: 'documents',
  },
  {
    name: s__('ProductAnalytics|Page Language'),
    category: 'pages',
    dbField: 'docEncoding',
    icon: 'documents',
  },
  {
    name: s__('ProductAnalytics|Host'),
    category: 'pages',
    dbField: 'docHost',
    icon: 'documents',
  },
  {
    name: s__('ProductAnalytics|Referer'),
    category: 'users',
    dbField: 'referer',
    icon: 'user',
  },
  {
    name: s__('ProductAnalytics|Language'),
    category: 'users',
    dbField: 'userLanguage',
    icon: 'user',
  },
  {
    name: s__('ProductAnalytics|Viewport'),
    category: 'users',
    dbField: 'vpSize',
    icon: 'user',
  },
  {
    name: s__('ProductAnalytics|Browser Family'),
    category: 'users',
    dbField: 'parsedUaUaFamily',
    icon: 'user',
  },
  {
    name: s__('ProductAnalytics|Browser'),
    category: 'users',
    dbField: ['parsedUaUaFamily', 'parsedUaUaVersion'],
    icon: 'user',
  },
  {
    name: s__('ProductAnalytics|OS'),
    category: 'users',
    dbField: 'parsedUaOsFamily',
    icon: 'user',
  },
  {
    name: s__('ProductAnalytics|OS Version'),
    category: 'users',
    dbField: ['parsedUaOsFamily', 'parsedUaOsVersion'],
    icon: 'user',
  },
];
