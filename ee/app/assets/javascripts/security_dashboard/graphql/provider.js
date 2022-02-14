import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import tempResolvers from '~/security_configuration/resolver';

Vue.use(VueApollo);

const defaultClient = createDefaultClient({
  ...tempResolvers,
});

export default new VueApollo({
  defaultClient,
});
