import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import { __ } from '~/locale';

export const TestCaseTabs = [
  {
    id: 'state-opened',
    name: STATUS_OPEN,
    title: __('Open'),
    titleTooltip: __('Filter by test cases that are currently open.'),
  },
  {
    id: 'state-archived',
    name: STATUS_CLOSED, // Change this to `Archived` once supported
    title: __('Archived'),
    titleTooltip: __('Filter by test cases that are currently archived.'),
  },
  {
    id: 'state-all',
    name: STATUS_ALL,
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
