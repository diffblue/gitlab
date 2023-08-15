<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { s__ } from '~/locale';

export default {
  name: 'GeoSiteActionsDesktop',
  i18n: {
    editButtonTooltip: s__('Geo|Edit %{siteType} site'),
    removeButtonTooltip: s__('Geo|Remove %{siteType} site'),
  },
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    site: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['canRemoveSite']),
    siteType() {
      return this.site.primary ? s__('Geo|primary') : s__('Geo|secondary');
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      v-gl-tooltip
      :title="
        /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ sprintf(
          $options.i18n.editButtonTooltip,
          { siteType },
        ) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
      "
      :aria-label="
        /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ sprintf(
          $options.i18n.editButtonTooltip,
          { siteType },
        ) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
      "
      icon="pencil"
      class="gl-mr-3"
      data-testid="geo-desktop-edit-action"
      :href="site.webEditUrl"
    />
    <gl-button
      v-gl-tooltip
      :title="
        /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ sprintf(
          $options.i18n.removeButtonTooltip,
          { siteType },
        ) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
      "
      :aria-label="
        /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ sprintf(
          $options.i18n.removeButtonTooltip,
          { siteType },
        ) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
      "
      icon="remove"
      :disabled="!canRemoveSite(site.id)"
      data-testid="geo-desktop-remove-action"
      @click="$emit('remove')"
    />
  </div>
</template>
