import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import * as licenseMangementMutationTypes from 'ee/vue_shared/license_compliance/store/mutation_types';
import { LICENSE_LIST } from '../constants';

export default (store) => {
  store.subscribe(({ type }) => {
    switch (type) {
      case `${LICENSE_MANAGEMENT}/${licenseMangementMutationTypes.RECEIVE_DELETE_LICENSE}`:
        store.dispatch(`${LICENSE_LIST}/fetchLicenses`);
        break;
      default:
    }
  });
};
