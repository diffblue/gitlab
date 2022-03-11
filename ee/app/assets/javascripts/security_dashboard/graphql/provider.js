import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import tempResolver from './temp_resolver';

Vue.use(VueApollo);

const defaultClient = createDefaultClient({
  ...tempResolver,
});

export default new VueApollo({
  defaultClient,
});
