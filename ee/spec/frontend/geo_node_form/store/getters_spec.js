import * as getters from 'ee/geo_node_form/store/getters';
import createState from 'ee/geo_node_form/store/state';

describe('GeoNodeForm Store Getters', () => {
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
