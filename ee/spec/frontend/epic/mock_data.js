import metaFixture from 'test_fixtures/epic/mock_meta.json';
import mockDataFixture from 'test_fixtures/epic/mock_data.json';
import { TEST_HOST } from 'spec/test_constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const meta = JSON.parse(metaFixture.meta);
const initial = JSON.parse(metaFixture.initial);

export const mockEpicMeta = {
  ...convertObjectPropsToCamelCase(meta, {
    deep: true,
  }),
  allowSubEpics: true,
};

export const mockEpicData = convertObjectPropsToCamelCase(
  {
    ...mockDataFixture,
    ...initial,
    endpoint: TEST_HOST,
    sidebarCollapsed: false,
  },
  { deep: true },
);

export const mockDatePickerProps = {
  blockClass: 'epic-date',
  sidebarCollapsed: false,
  showToggleSidebar: false,
  dateSaveInProgress: false,
  canUpdate: true,
  label: 'Date',
  datePickerLabel: 'Fixed date',
  selectedDate: null,
  selectedDateIsFixed: true,
  dateFromMilestones: null,
  dateFixed: null,
  dateFromMilestonesTooltip: 'Select an issue with milestone to set date',
  isDateInvalid: false,
  dateInvalidTooltip: 'Selected date is invalid',
};

export const mockLabels = [
  {
    id: 26,
    title: 'Foo Label',
    description: 'Foobar',
    color: '#BADA55',
    text_color: '#FFFFFF',
  },
];

export const mockAncestors = [
  {
    id: 1,
    title: 'Parent epic',
    url: '/groups/gitlab-org/-/epics/6',
  },
  {
    id: 2,
    title: 'Parent epic 2',
    url: '/groups/gitlab-org/-/epics/7',
  },
];
