import { validateName, validateUrl, validateCapacity } from 'ee/geo_site_form/validations';
import { STRING_OVER_255 } from './mock_data';

describe('GeoSiteForm Validations', () => {
  describe.each`
    data               | errorMessage
    ${null}            | ${"Site name can't be blank"}
    ${''}              | ${"Site name can't be blank"}
    ${STRING_OVER_255} | ${'Site name should be between 1 and 255 characters'}
    ${'Test'}          | ${''}
  `(`validateName`, ({ data, errorMessage }) => {
    let validateNameRes = '';

    beforeEach(() => {
      validateNameRes = validateName(data);
    });

    it(`return ${errorMessage} when data is ${data}`, () => {
      expect(validateNameRes).toBe(errorMessage);
    });
  });

  describe.each`
    data                    | errorMessage
    ${null}                 | ${"URL can't be blank"}
    ${''}                   | ${"URL can't be blank"}
    ${'abcd'}               | ${'URL must be a valid url (ex: https://gitlab.com)'}
    ${'https://gitlab.com'} | ${''}
  `(`validateUrl`, ({ data, errorMessage }) => {
    let validateUrlRes = '';

    beforeEach(() => {
      validateUrlRes = validateUrl(data);
    });

    it(`return ${errorMessage} when data is ${data}`, () => {
      expect(validateUrlRes).toBe(errorMessage);
    });
  });

  describe.each`
    data    | errorMessage
    ${null} | ${"Mock field can't be blank"}
    ${''}   | ${"Mock field can't be blank"}
    ${-1}   | ${'Mock field should be between 1-999'}
    ${0}    | ${'Mock field should be between 1-999'}
    ${1}    | ${''}
    ${999}  | ${''}
    ${1000} | ${'Mock field should be between 1-999'}
  `(`validateCapacity`, ({ data, errorMessage }) => {
    let validateCapacityRes = '';

    beforeEach(() => {
      validateCapacityRes = validateCapacity({ data, label: 'Mock field' });
    });

    it(`return ${errorMessage} when data is ${data}`, () => {
      expect(validateCapacityRes).toBe(errorMessage);
    });
  });
});
