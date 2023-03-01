import { thWidthPercent } from '~/lib/utils/table_utility';
import { __, s__ } from '~/locale';

// Billable Seats HTTP headers
export const HEADER_TOTAL_ENTRIES = 'x-total';
export const HEADER_PAGE_NUMBER = 'x-page';
export const HEADER_ITEMS_PER_PAGE = 'x-per-page';

export const FIELDS = [
  {
    key: 'disclosure',
    label: '',
    thClass: 'gl-p-0!',
    tdClass: 'gl-p-0! gl-vertical-align-middle!',
  },
  {
    key: 'user',
    label: __('User'),
    // eslint-disable-next-line @gitlab/require-i18n-strings
    thClass: `${thWidthPercent(30)} gl-pl-2!`,
    tdClass: 'gl-vertical-align-middle! gl-pl-2!',
  },
  {
    key: 'email',
    label: __('Email'),
    thClass: thWidthPercent(20),
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'lastActivityTime',
    label: __('Last activity'),
    thClass: thWidthPercent(20),
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'lastLoginAt',
    label: __('Last login'),
    thClass: thWidthPercent(20),
    tdClass: 'gl-vertical-align-middle!',
  },
  {
    key: 'actions',
    label: '',
    thClass: thWidthPercent(10),
    tdClass: 'gl-vertical-align-middle! text-right',
  },
];

export const DETAILS_FIELDS = [
  { key: 'source_full_name', label: s__('Billing|Direct memberships') },
  { key: 'created_at', label: __('Access granted') },
  { key: 'expires_at', label: __('Access expires') },
  { key: 'role', label: __('Role') },
].map((field) => ({
  ...field,
  thClass: 'gl-border-0!',
  tdClass: 'gl-border-0! gl-vertical-align-middle!',
}));

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
  {
    id: 30,
    title: __('Last login'),
    sortDirection: {
      descending: 'recent_sign_in',
      ascending: 'oldest_sign_in',
    },
  },
];

export const EXPLORE_PAID_PLANS_CLICKED = 'explore_paid_plans_clicked';
