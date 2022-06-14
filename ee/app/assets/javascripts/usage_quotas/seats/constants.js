import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { thWidthPercent } from '~/lib/utils/table_utility';
import { __, s__ } from '~/locale';

// Billable Seats HTTP headers
export const HEADER_TOTAL_ENTRIES = 'x-total';
export const HEADER_PAGE_NUMBER = 'x-page';
export const HEADER_ITEMS_PER_PAGE = 'x-per-page';

const ALL_FIELDS = [
  {
    key: 'user',
    label: __('User'),
    thClass: thWidthPercent(30),
  },
  {
    key: 'email',
    label: __('Email'),
    thClass: thWidthPercent(20),
  },
  {
    key: 'lastActivityTime',
    label: __('Last activity'),
    thClass: thWidthPercent(20),
  },
  {
    key: 'membershipState',
    label: __('In a seat'),
    thClass: thWidthPercent(10),
  },
  {
    key: 'actions',
    label: '',
    thClass: thWidthPercent(20),
    tdClass: 'text-right',
  },
];

export const STANDARD_FIELDS = ALL_FIELDS.filter(({ key }) => key !== 'membershipState');
export const FIELDS_WITH_MEMBERSHIP_TOGGLE = ALL_FIELDS;

export const DETAILS_FIELDS = [
  {
    key: 'source_full_name',
    label: s__('Billing|Direct memberships'),
    thClass: thWidthPercent(40),
  },
  { key: 'created_at', label: __('Access granted'), thClass: thWidthPercent(40) },
  { key: 'expires_at', label: __('Access expires'), thClass: thWidthPercent(40) },
  { key: 'role', label: __('Role'), thClass: thWidthPercent(40) },
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

export const MEMBER_AWAITING_STATE = 'awaiting';
export const MEMBER_ACTIVE_STATE = 'active';
export const DISMISS_SEATS_ALERT_COOKIE_NAME = 'dismiss_seats_alert_usage_quotas_page';
export const RENDER_SEATS_PAGE_TRACK_LABEL = 'usage_quotas_page_viewed';
export const RENDER_SEATS_ALERT_TRACK_LABEL = 'over_limit_alert_viewed';
export const DISMISS_SEATS_ALERT_TRACK_LABEL = 'over_limit_alert_dismissed';
export const EXPLORE_PAID_PLANS_CLICKED = 'explore_paid_plans_clicked';
