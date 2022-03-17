<script>
import { GlLink } from '@gitlab/ui';
import { Namespace } from 'ee/iterations/constants';
import { getIterationPeriod } from 'ee/iterations/utils';
import IterationTitle from 'ee/iterations/components/iteration_title.vue';

export default {
  components: {
    GlLink,
    IterationTitle,
  },
  props: {
    iterations: {
      type: Array,
      required: false,
      default: () => [],
    },
    namespaceType: {
      type: String,
      required: false,
      default: Namespace.Group,
      validator: (value) => Object.values(Namespace).includes(value),
    },
  },
  methods: {
    getIterationPeriod,
  },
};
</script>

<template>
  <ul v-if="iterations.length > 0" class="content-list">
    <li v-for="iteration in iterations" :key="iteration.id" class="gl-p-4!">
      <div>
        <gl-link :href="iteration.scopedPath || iteration.webPath">
          <strong>{{ getIterationPeriod(iteration) }}</strong>
        </gl-link>
      </div>
      <iteration-title
        v-if="iteration.title"
        :title="iteration.title"
        class="text-secondary gl-mt-3"
      />
    </li>
  </ul>
  <div v-else class="nothing-here-block">
    {{ __('No iterations to show') }}
  </div>
</template>
