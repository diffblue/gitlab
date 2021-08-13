<script>
// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
/* eslint-disable @gitlab/no-runtime-template-compiler */
import { __ } from '~/locale';
import SidebarDropdownWidgetFoss from '~/sidebar/components/sidebar_dropdown_widget.vue';
import {
  IssuableAttributeState,
  IssuableAttributeType,
  issuableAttributesQueries,
} from '../constants';

export default {
  extends: SidebarDropdownWidgetFoss,
  IssuableAttributeState,
  issuableAttributesQueries,
  i18n: {
    [IssuableAttributeType.Milestone]: __('Milestone'),
    [IssuableAttributeType.Iteration]: __('Iteration'),
    [IssuableAttributeType.Epic]: __('Epic'),
    none: __('None'),
    expired: __('(expired)'),
  },
  props: {
    issuableAttribute: {
      type: String,
      required: true,
      validator(value) {
        return [
          IssuableAttributeType.Milestone,
          IssuableAttributeType.Iteration,
          IssuableAttributeType.Epic,
        ].includes(value);
      },
    },
  },
};
</script>
