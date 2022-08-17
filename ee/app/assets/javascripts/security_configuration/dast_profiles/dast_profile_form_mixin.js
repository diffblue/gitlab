import { isEqual } from 'lodash';
import { serializeFormObject } from '~/lib/utils/forms';
import validation from '~/vue_shared/directives/validation';

export default () => ({
  directives: {
    validation: validation(),
  },
  props: {
    profile: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    projectFullPath: {
      type: String,
      required: true,
    },
    stacked: {
      type: Boolean,
      required: false,
      default: false,
    },
    isProfileInUse: {
      type: Boolean,
      required: false,
      default: false,
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
