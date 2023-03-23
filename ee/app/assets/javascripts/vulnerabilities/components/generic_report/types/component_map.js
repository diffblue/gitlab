import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { REPORT_TYPES } from './constants';

const REPORT_TYPE_TO_COMPONENT_MAP = {
  [REPORT_TYPES.list]: () => import('./list.vue'),
  [REPORT_TYPES.url]: () => import('./url.vue'),
  [REPORT_TYPES.diff]: () => import('./diff.vue'),
  [REPORT_TYPES.namedList]: () => import('./named_list.vue'),
  [REPORT_TYPES.text]: () => import('./value.vue'),
  [REPORT_TYPES.value]: () => import('./value.vue'),
  [REPORT_TYPES.moduleLocation]: () => import('./module_location.vue'),
  [REPORT_TYPES.fileLocation]: () => import('./file_location.vue'),
  [REPORT_TYPES.table]: () => import('./table.vue'),
  [REPORT_TYPES.code]: () => import('./code.vue'),
  [REPORT_TYPES.markdown]: () => import('./markdown.vue'),
  [REPORT_TYPES.commit]: () => import('./commit.vue'),
};

export const getComponentNameForType = (reportType) =>
  `ReportType${capitalizeFirstCharacter(reportType)}`;

export const REPORT_COMPONENTS = Object.fromEntries(
  Object.entries(REPORT_TYPE_TO_COMPONENT_MAP).map(([reportType, component]) => [
    getComponentNameForType(reportType),
    component,
  ]),
);
