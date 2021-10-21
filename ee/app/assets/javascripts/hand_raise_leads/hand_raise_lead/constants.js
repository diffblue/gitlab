import { __, s__ } from '~/locale';

export const i18n = Object.freeze({
  firstNameLabel: __('First Name'),
  lastNameLabel: __('Last Name'),
  companyNameLabel: __('Company Name'),
  companySizeLabel: __('Number of employees'),
  companySizeSelectPrompt: __('- Select -'),
  phoneNumberLabel: __('Telephone number'),
  phoneNumberDescription: __('Provide a number our sales team can use to call you.'),
  countryLabel: __('Country'),
  countrySelectPrompt: __('Please select a country'),
  stateLabel: __('State/Province/City'),
  stateSelectPrompt: s__('PQL|Please select a city or state'),
  commentLabel: s__('PQL|Message for the Sales team (optional)'),
  buttonText: s__('PQL|Contact sales'),
  modalTitle: s__('PQL|Contact our Sales team'),
  modalPrimary: s__('PQL|Submit information'),
  modalCancel: s__('PQL|Cancel'),
  modalHeaderText: s__(
    'PQL|Hello %{userName}. Before putting you in touch with our sales team, we would like you to verify and complete the information below.',
  ),
  modalFooterText: s__(
    'PQL|By providing my contact information, I agree GitLab may contact me via email about its product, services and events. You may opt-out at any time by unsubscribing in emails or visiting our communication preference center.',
  ),
  handRaiseActionError: s__('PQL|An error occurred while sending hand raise lead.'),
  handRaiseActionSuccess: s__(
    'PQL|Thank you for reaching out! Our sales team will get back to you soon.',
  ),
});

export const companySizes = Object.freeze([
  {
    name: '1 - 99',
    id: '1-99',
  },
  {
    name: '100 - 499',
    id: '100-499',
  },
  {
    name: '500 - 1,999',
    id: '500-1,999',
  },
  {
    name: '2,000 - 9,999',
    id: '2,000-9,999',
  },
  {
    name: '10,000 +',
    id: '10,000+',
  },
]);

export const COUNTRIES_WITH_STATES_ALLOWED = ['US', 'CA'];
