export const COUNTRY_WITH_STATES = 'US';
export const STATE = 'CA';
export const COUNTRIES = [
  { id: COUNTRY_WITH_STATES, name: 'United States', flag: 'US', internationalDialCode: '1' },
  { id: 'CA', name: 'Canada', flag: 'CA', internationalDialCode: '1' },
  { id: 'NL', name: 'Netherlands', flag: 'NL', internationalDialCode: '31' },
];

export const STATES = [
  { countryId: COUNTRY_WITH_STATES, id: STATE, name: 'California' },
  { countryId: 'CA', id: 'BC', name: 'British Columbia' },
];

export const FORM_DATA = {
  firstName: 'Joe',
  lastName: 'Doe',
  companyName: 'ACME',
  companySize: '1-99',
  phoneNumber: '192919',
  country: COUNTRY_WITH_STATES,
  state: STATE,
};
