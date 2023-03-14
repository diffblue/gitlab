import { VALIDATION_FIELD_KEYS } from '../constants';

const createState = (sitesPath) => ({
  sitesPath,
  isLoading: false,
  synchronizationNamespaces: [],
  formErrors: Object.values(VALIDATION_FIELD_KEYS).reduce(
    (acc, cur) => ({ ...acc, [cur]: '' }),
    {},
  ),
});
export default createState;
