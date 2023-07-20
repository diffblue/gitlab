import { thWidthPercent } from '~/lib/utils/table_utility';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';

// Billable Seats HTTP headers
export const HEADER_TOTAL_ENTRIES = 'x-total';
export const HEADER_PAGE_NUMBER = 'x-page';
export const HEADER_ITEMS_PER_PAGE = 'x-per-page';
export const PLAN_CODE_FREE = 'free';
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
export const seatsInUseLink = helpPagePath('subscriptions/gitlab_com/index', {
  anchor: 'how-seat-usage-is-determined',
});
export const seatsOwedLink = helpPagePath('subscriptions/gitlab_com/index', {
  anchor: 'seats-owed',
});
export const seatsUsedLink = helpPagePath('subscriptions/gitlab_com/index', {
  anchor: 'view-your-gitlab-saas-subscription',
});
export const codeSuggestionsInfoLink = helpPagePath(
  'user/project/repository/code_suggestions.html',
);
export const emailNotVisibleTooltipText = s__(
  'Billing|An email address is only visible for users with public emails.',
);
export const filterUsersPlaceholder = __('Filter users');
export const pendingMembersAlertButtonText = s__('Billing|View pending approvals');
export const seatsInSubscriptionTextForFreePlan = s__('Billings|Free seats used');
export const seatsInSubscriptionText = s__('Billings|Seats in use / Seats in subscription');
export const seatsAvailableText = s__('Billings|Seats in use / Seats available');
export const seatsTooltipText = s__('Billings|Free groups are limited to %{number} seats.');
export const seatsTooltipTrialText = s__(
  'Billings|Free tier and trial groups can invite a maximum of 20 members per day.',
);
export const inASeatLabel = s__('Billings|In a seat');
export const unlimited = __('Unlimited');
export const seatsUsedText = __('Max seats used');
export const seatsUsedHelpText = __('Learn more about max seats used');
export const seatsOwedText = __('Seats owed');
export const seatsOwedHelpText = __('Learn more about seats owed');
export const addSeatsText = s__('Billing|Add seats');
export const subscriptionEndDateText = s__('Billing|Subscription end');
export const subscriptionStartDateText = s__('Billing|Subscription start');
export const seatsUsedDescriptionText = s__('Billing|%{plan} SaaS Plan seats used');
export const codeSuggestionIntroDescriptionText = __('Introducing the Code Suggestions add-on');
export const codeSuggestionsInfoText = __(
  `Enhance your coding experience with intelligent recommendations. %{linkStart}Code Suggestions%{linkEnd} uses generative AI to suggest code while you're developing. Not available for Guest roles.`,
);
export const learnMoreText = __('Learn more');
export const codeSuggestionsLearnMoreLink = `${PROMO_URL}/solutions/code-suggestions/`;
