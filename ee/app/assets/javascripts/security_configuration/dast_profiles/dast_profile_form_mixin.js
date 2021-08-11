import { isEqual } from 'lodash';
import { serializeFormObject } from '~/lib/utils/forms';
import validation from '~/vue_shared/directives/validation';

export default () => ({
  directives: {
    validation: validation(),
  },
  inject: ['projectFullPath'],
  props: {
    profile: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    isEdit() {
      return Boolean(this.profile.id);
    },
    formTouched() {
      return !isEqual(serializeFormObject(this.form.fields), this.initialFormValues);
    },
    isPolicyProfile() {
      return Boolean(this.profile.referencedInSecurityPolicies?.length);
    },
  },
});
