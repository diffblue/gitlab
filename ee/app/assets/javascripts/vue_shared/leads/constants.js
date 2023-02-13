import { __ } from '~/locale';

export const LEADS_FIRST_NAME_LABEL = __('First Name');
export const LEADS_LAST_NAME_LABEL = __('Last Name');
export const LEADS_COMPANY_NAME_LABEL = __('Company Name');
export const LEADS_COMPANY_SIZE_LABEL = __('Number of employees');
export const LEADS_PHONE_NUMBER_LABEL = __('Telephone number');
export const LEADS_COUNTRY_LABEL = __('Country / Region');
export const LEADS_COUNTRY_PROMPT = __('Please select a country / region');

export const COUNTRIES_WITH_STATES_ALLOWED = ['US', 'CA'];

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
