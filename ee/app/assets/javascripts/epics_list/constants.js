import { __ } from '~/locale';

export const epicsSortOptions = [
  {
    id: 1,
    title: __('Created date'),
    sortDirection: {
      descending: 'CREATED_AT_DESC',
      ascending: 'CREATED_AT_ASC',
    },
  },
  {
    id: 2,
    title: __('Updated date'),
    sortDirection: {
      descending: 'UPDATED_AT_DESC',
      ascending: 'UPDATED_AT_ASC',
    },
  },
  {
    id: 3,
    title: __('Start date'),
    sortDirection: {
      descending: 'start_date_desc',
      ascending: 'start_date_asc',
    },
  },
  {
    id: 4,
    title: __('Due date'),
    sortDirection: {
      descending: 'end_date_desc',
      ascending: 'end_date_asc',
    },
  },
  {
    id: 5,
    title: __('Title'),
    sortDirection: {
      descending: 'TITLE_DESC',
      ascending: 'TITLE_ASC',
    },
  },
];

export const filterStateEmptyMessage = {
  opened: __('There are no open epics'),
  closed: __('There are no closed epics'),
};
