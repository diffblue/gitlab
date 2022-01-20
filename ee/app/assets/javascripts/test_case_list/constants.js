import { __ } from '~/locale';

export const TestCaseStates = {
  Opened: 'opened',
  Closed: 'closed', // Change this to `archived` once supported
  All: 'all',
};

export const TestCaseTabs = [
  {
    id: 'state-opened',
    name: TestCaseStates.Opened,
    title: __('Open'),
    titleTooltip: __('Filter by test cases that are currently open.'),
  },
  {
    id: 'state-archived',
    name: TestCaseStates.Closed, // Change this to `Archived` once supported
    title: __('Archived'),
    titleTooltip: __('Filter by test cases that are currently archived.'),
  },
  {
    id: 'state-all',
    name: TestCaseStates.All,
    title: __('All'),
    titleTooltip: __('Show all test cases.'),
  },
];

export const AvailableSortOptions = [
  {
    id: 1,
    title: __('Created date'),
    sortDirection: {
      descending: 'created_desc',
      ascending: 'created_asc',
    },
  },
  {
    id: 2,
    title: __('Updated date'),
    sortDirection: {
      descending: 'updated_desc',
      ascending: 'updated_asc',
    },
  },
];

export const FilterStateEmptyMessage = {
  opened: __('There are no open test cases'),
  closed: __('There are no archived test cases'),
};

export const DEFAULT_PAGE_SIZE = 20;
