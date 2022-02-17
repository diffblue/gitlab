import { __, s__, n__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const OVERAGE_MODAL_LINK = helpPagePath('subscriptions/quarterly_reconciliation');

export const OVERAGE_MODAL_TITLE = s__('MembersOverage|You are about to incur additional charges');
export const OVERAGE_MODAL_BACK_BUTTON = __('Back');
export const OVERAGE_MODAL_CONTINUE_BUTTON = __('Continue');
export const OVERAGE_MODAL_LINK_TEXT = __('Learn more.');
export const overageModalInfoText = (quantity) =>
  n__(
    'MembersOverage|Your subscription includes %d seat.',
    'MembersOverage|Your subscription includes %d seats.',
    quantity,
  );
export const overageModalInfoWarning = (quantity, groupName) =>
  sprintf(
    n__(
      'MembersOverage|If you continue, the %{groupName} group will have %{quantity} seat in use and will be billed for the overage.',
      'MembersOverage|If you continue, the %{groupName} group will have %{quantity} seats in use and will be billed for the overage.',
      quantity,
    ),
    {
      groupName,
      quantity,
    },
  );
