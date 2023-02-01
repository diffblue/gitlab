<script>
import { GlAccordion, GlAccordionItem, GlSprintf } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { s__ } from '~/locale';

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlSprintf,
  },
  computed: {
    ...mapState(['loading', 'protectedEnvironments']),
  },
  mounted() {
    this.fetchProtectedEnvironments();
  },
  methods: {
    ...mapActions(['fetchProtectedEnvironments']),
  },
  i18n: {
    title: s__(
      'ProtectedEnvironments|List of protected environments (%{protectedEnvironmentsCount})',
    ),
  },
};
</script>
<template>
  <div data-testid="protected-environments-list">
    <h5>
      <gl-sprintf :message="$options.i18n.title">
        <template #protectedEnvironmentsCount>{{ protectedEnvironments.length }}</template>
      </gl-sprintf>
    </h5>
    <gl-accordion :header-level="6">
      <gl-accordion-item
        v-for="environment in protectedEnvironments"
        :key="environment.name"
        :title="environment.name"
      />
    </gl-accordion>
  </div>
</template>
