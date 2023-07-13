import { shallowMount } from '@vue/test-utils';
import component from 'ee/environments_dashboard/components/dashboard/environment.vue';
import EnvironmentHeader from 'ee/environments_dashboard/components/dashboard/environment_header.vue';
import Alert from 'ee/vue_shared/dashboards/components/alerts.vue';
import Commit from '~/vue_shared/components/commit.vue';
import environment from './mock_environment.json';

describe('Environment', () => {
  let wrapper;
  let propsData;

  beforeEach(() => {
    propsData = {
      environment,
    };
    wrapper = shallowMount(component, {
      propsData,
    });
  });

  it('matchs the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('wrapped components', () => {
    describe('environment header', () => {
      it('binds environment', () => {
        expect(wrapper.findComponent(EnvironmentHeader).props('environment')).toBe(environment);
      });
    });

    describe('alerts', () => {
      let alert;

      beforeEach(() => {
        alert = wrapper.findComponent(Alert);
      });
      it('binds alert count to count', () => {
        expect(alert.props('count')).toBe(environment.alert_count);
      });
    });

    describe('commit', () => {
      let commit;

      beforeEach(() => {
        commit = wrapper.findComponent(Commit);
      });

      it('binds commitRef', () => {
        expect(commit.props('commitRef')).toBe(wrapper.vm.commitRef);
      });

      it('binds short_id to shortSha', () => {
        expect(commit.props('shortSha')).toBe(environment.last_deployment.commit.short_id);
      });

      it('binds commitUrl', () => {
        expect(commit.props('commitUrl')).toBe(environment.last_deployment.commit.commit_url);
      });

      it('binds title', () => {
        expect(commit.props('title')).toBe(environment.last_deployment.commit.title);
      });

      it('binds author', () => {
        expect(commit.props('author')).toEqual({
          avatar_url: environment.last_deployment.commit.author_gravatar_url,
          path: `mailto:${environment.last_deployment.commit.author_email}`,
          username: environment.last_deployment.commit.author_name,
        });
      });

      it('binds tag', () => {
        expect(commit.props('tag')).toBe(environment.last_deployment.ref.tag);
      });
    });
  });

  it('renders an environment without a deployment', () => {
    propsData = {
      environment: {
        ...environment,
        last_deployment: null,
      },
    };
    wrapper = shallowMount(component, {
      propsData,
    });

    expect(wrapper.text()).toContain('This environment has no deployments yet.');
  });

  it('renders an environment with a deployment without a deployable', () => {
    propsData = {
      environment: {
        ...environment,
        last_deployment: {
          ...environment.last_deployment,
          deployable: null,
        },
      },
    };
    wrapper = shallowMount(component, {
      propsData,
    });

    expect(wrapper.text()).toContain('API');
  });
});
