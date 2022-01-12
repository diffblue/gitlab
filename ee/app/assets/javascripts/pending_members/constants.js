import { s__, __ } from '~/locale';

// Pending members HTTP headers
export const HEADER_TOTAL_ENTRIES = 'x-total';
export const HEADER_PAGE_NUMBER = 'x-page';
export const HEADER_ITEMS_PER_PAGE = 'x-per-page';

export const AWAITING_MEMBER_SIGNUP_TEXT = s__('Billing|Awaiting member signup');
export const PENDING_MEMBERS_LIST_ERROR = s__(
  'Billing|An error occurred while loading pending members list',
);

export const LABEL_APPROVE = __('Approve');
export const LABEL_CONFIRM = __('Confirm approval');
export const LABEL_CONFIRM_APPROVE = __('Are you sure you want to approve %{user}?');
export const APPROVAL_SUCCESSFUL_MESSAGE = s__('Billing|%{user} was successfully approved');
export const APPROVAL_ERROR_MESSAGE = s__('Billing|An error occurred while approving %{user}');
