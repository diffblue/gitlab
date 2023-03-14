import * as getters from 'ee/geo_site_form/store/getters';
import createState from 'ee/geo_site_form/store/state';

describe('GeoSiteForm Store Getters', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('formHasError', () => {
    it('with error returns true', () => {
      state.formErrors.name = 'Error';

      expect(getters.formHasError(state)).toBe(true);
    });

    it('without error returns false', () => {
      expect(getters.formHasError(state)).toBe(false);
    });
  });
});
