import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Panel from '~/google_cloud/configuration/panel.vue';

describe('google_cloud/configuration/panel', () => {
  let wrapper;

  const props = {
    configurationUrl: 'configuration-url',
    deploymentsUrl: 'deployments-url',
    databasesUrl: 'databases-url',
    serviceAccounts: [],
    createServiceAccountUrl: 'create-service-account-url',
    emptyIllustrationUrl: 'empty-illustration-url',
    gcpRegions: [],
    configureGcpRegionsUrl: 'configure-gcp-regions-url',
    revokeOauthUrl: 'revoke-oauth-url',
  };

  beforeEach(() => {
    wrapper = shallowMountExtended(Panel, { propsData: props });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('contains incubation banner', () => {
    const target = wrapper.findByTestId('incubation-banner');
    expect(target.exists()).toBe(true);
  });

  it('contains google cloud menu with `configuration` active', () => {
    const target = wrapper.findByTestId('google-cloud-menu');
    expect(target.exists()).toBe(true);
    expect(target.props('active')).toBe('configuration');
    expect(target.props('configurationUrl')).toBe(props.configurationUrl);
    expect(target.props('deploymentsUrl')).toBe(props.deploymentsUrl);
    expect(target.props('databasesUrl')).toBe(props.databasesUrl);
  });

  it('contains service accounts list', () => {
    const target = wrapper.findByTestId('service-accounts-list');
    expect(target.exists()).toBe(true);
    expect(target.props('list')).toBe(props.serviceAccounts);
    expect(target.props('createUrl')).toBe(props.createServiceAccountUrl);
    expect(target.props('emptyIllustrationUrl')).toBe(props.emptyIllustrationUrl);
  });

  it('contains gcp regions list', () => {
    const target = wrapper.findByTestId('gcp-regions-list');
    expect(target.props('list')).toBe(props.gcpRegions);
    expect(target.props('createUrl')).toBe(props.configureGcpRegionsUrl);
    expect(target.props('emptyIllustrationUrl')).toBe(props.emptyIllustrationUrl);
  });

  it('contains revoke oauth', () => {
    const target = wrapper.findByTestId('revoke-oauth');
    expect(target.props('url')).toBe(props.revokeOauthUrl);
  });
});
