import { GlLink, GlBadge, GlIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import component from 'ee/environments_dashboard/components/dashboard/environment_header.vue';
import ReviewAppLink from '~/vue_merge_request_widget/components/review_app_link.vue';

describe('Environment Header', () => {
  let wrapper;
  let propsData;

  beforeEach(() => {
    propsData = {
      environment: {
        environment_path: '/enivronment/1',
        name: 'staging',
        external_url: 'http://example.com',
      },
    };
  });

  describe('renders name and link to app', () => {
    beforeEach(() => {
      wrapper = mount(component, {
        propsData,
      });
    });

    it('renders the environment name', () => {
      expect(wrapper.find('.js-environment-name').text()).toBe(propsData.environment.name);
    });

    it('renders a link to the environment page', () => {
      expect(wrapper.findComponent(GlLink).attributes('href')).toBe(
        propsData.environment.environment_path,
      );
    });

    it('does not show a badge with the number of environments in the folder', () => {
      expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
    });

    it('renders a link to the external app', () => {
      expect(wrapper.findComponent(ReviewAppLink).attributes('href')).toBe(
        propsData.environment.external_url,
      );
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('with environments grouped into a folder', () => {
    beforeEach(() => {
      propsData.environment.size = 5;
      propsData.environment.within_folder = true;
      propsData.environment.name = 'review/testing';

      wrapper = shallowMount(component, {
        propsData,
      });
    });

    it('shows a badge with the number of other environments in the folder', () => {
      const expected = propsData.environment.size.toString();
      expect(wrapper.findComponent(GlBadge).text()).toBe(expected);
    });

    it('shows an icon stating the environment is one of many in a folder', () => {
      expect(wrapper.findComponent(GlIcon).attributes('name')).toBe('information');
      expect(wrapper.findComponent(GlIcon).attributes('title')).toMatch(/last updated environment/);
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('has errors', () => {
    beforeEach(() => {
      propsData.hasErrors = true;

      wrapper = shallowMount(component, {
        propsData,
      });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('has a failed pipeline', () => {
    beforeEach(() => {
      propsData.hasPipelineFailed = true;

      wrapper = shallowMount(component, {
        propsData,
      });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
