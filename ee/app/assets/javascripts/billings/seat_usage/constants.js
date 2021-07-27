import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { thWidthClass } from '~/lib/utils/table_utility';
import { __, s__ } from '~/locale';

export const FIELDS = [
  {
    key: 'user',
    label: __('User'),
    thClass: thWidthClass(40),
  },
  {
    key: 'email',
    label: __('Email'),
    thClass: thWidthClass(40),
  },
  {
    key: 'lastActivityTime',
    label: __('Last activity'),
    thClass: thWidthClass(40),
  },
  {
    key: 'actions',
    label: '',
    tdClass: 'text-right',
    customStyle: { width: '35px' },
  },
];

export const DETAILS_FIELDS = [
  { key: 'source_full_name', label: s__('Billing|Direct memberships'), thClass: thWidthClass(40) },
  { key: 'created_at', label: __('Access granted'), thClass: thWidthClass(40) },
  { key: 'expires_at', label: __('Access expires'), thClass: thWidthClass(40) },
  { key: 'role', label: __('Role'), thClass: thWidthClass(40) },
];

export const CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_ID = 'cannot-remove-member-modal';
export const CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_TITLE = s__('Billing|Cannot remove user');
export const CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT = s__(
  `Billing|Members who were invited via a group invitation cannot be removed.
  You can either remove the entire group, or ask an Owner of the invited group to remove the member.`,
);
export const REMOVE_BILLABLE_MEMBER_MODAL_ID = 'billable-member-remove-modal';
export const REMOVE_BILLABLE_MEMBER_MODAL_CONTENT_TEXT_TEMPLATE = s__(
  `Billing|You are about to remove user %{username} from your subscription.
If you continue, the user will be removed from the %{namespace}
group and all its subgroups and projects. This action can't be undone.`,
);
export const AVATAR_SIZE = 32;
export const SEARCH_DEBOUNCE_MS = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;

export const SORT_OPTIONS = [
  {
    id: 10,
    title: __('Last Activity'),
    sortDirection: {
      descending: 'last_activity_on_desc',
      ascending: 'last_activity_on_asc',
    },
  },
  {
    id: 20,
    title: __('Name'),
    sortDirection: {
      descending: 'name_desc',
      ascending: 'name_asc',
    },
  },
];
