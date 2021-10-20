import { LICENSE_LIST } from 'ee/license_compliance/store/constants';
import createStore from 'ee/license_compliance/store/index';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import * as licenseMangementMutationTypes from 'ee/vue_shared/license_compliance/store/mutation_types';

describe('mediator', () => {
  let store;

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  it('triggers fetching of detected licenses after a license policy is deleted', () => {
    store.commit(`${LICENSE_MANAGEMENT}/${licenseMangementMutationTypes.RECEIVE_DELETE_LICENSE}`);
    expect(store.dispatch).toHaveBeenCalledWith(`${LICENSE_LIST}/fetchLicenses`);
  });
});
