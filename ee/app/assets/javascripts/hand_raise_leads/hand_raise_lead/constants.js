import { __, s__ } from '~/locale';

export const PQL_COMPANY_SIZE_PROMPT = __('- Select -');
export const PQL_PHONE_DESCRIPTION = __('Provide a number our sales team can use to call you.');
export const PQL_STATE_LABEL = __('State/Province/City');
export const PQL_STATE_PROMPT = s__('PQL|Please select a city or state');
export const PQL_COMMENT_LABEL = s__('PQL|Message for the Sales team (optional)');
export const PQL_BUTTON_TEXT = s__('PQL|Contact sales');
export const PQL_MODAL_TITLE = s__('PQL|Contact our Sales team');
export const PQL_MODAL_PRIMARY = s__('PQL|Submit information');
export const PQL_MODAL_CANCEL = s__('PQL|Cancel');
export const PQL_MODAL_HEADER_TEXT = s__(
  'PQL|Hello %{userName}. Before putting you in touch with our sales team, we would like you to verify and complete the information below.',
);
export const PQL_MODAL_FOOTER_TEXT = s__(
  'PQL|By providing my contact information, I agree GitLab may contact me via email about its product, services and events. You may opt-out at any time by unsubscribing in emails or visiting our communication preference center.',
);
export const PQL_HAND_RAISE_ACTION_ERROR = s__(
  'PQL|An error occurred while sending hand raise lead.',
);
export const PQL_HAND_RAISE_ACTION_SUCCESS = s__(
  'PQL|Thank you for reaching out! Our sales team will get back to you soon.',
);
