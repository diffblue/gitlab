import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const GRIDSTACK_MARGIN = 10;
export const GRIDSTACK_CSS_HANDLE = '.grid-stack-item-handle';
export const GRIDSTACK_CELL_HEIGHT = '120px';
export const GRIDSTACK_MIN_ROW = 1;

export const I18N_PANEL_EMPTY_STATE_MESSAGE = s__(
  'Analytics|No results match your query or filter.',
);
export const I18N_PANEL_ERROR_STATE_MESSAGE = s__('Analytics|Something went wrong.');
export const I18N_PANEL_ERROR_POPOVER_TITLE = s__('Analytics|Failed to fetch data');
export const I18N_PANEL_ERROR_POPOVER_MESSAGE = s__(
  'Analytics|Something went wrong while connecting to your data source. See %{linkStart}troubleshooting documentation%{linkEnd}.',
);
export const PANEL_TROUBLESHOOTING_URL = helpPagePath(
  '/user/analytics/analytics_dashboards#troubleshooting',
);

// TODO: Remove once the GitLab-UI issue is resolved.
// https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2278
export const PANEL_POPOVER_DELAY = {
  hide: 500,
};

export const CURSOR_GRABBING_CLASS = 'gl-cursor-grabbing!';

export const I18N_VISUALIZATION_SELECTOR_NEW = s__('ProductAnalytics|Create a visualization');

export const NEW_DASHBOARD_SLUG = 'new';
