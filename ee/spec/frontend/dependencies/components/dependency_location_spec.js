import { GlLink, GlIcon, GlIntersperse, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DependencyLocation from 'ee/dependencies/components/dependency_location.vue';
import DependencyPathViewer from 'ee/dependencies/components/dependency_path_viewer.vue';
import { trimText } from 'helpers/text_helper';
import * as Paths from './mock_data';

describe('Dependency Location component', () => {
  let wrapper;

  const createComponent = ({ propsData, ...options } = {}) => {
    wrapper = shallowMount(DependencyLocation, {
      propsData: { ...propsData },
      stubs: { GlLink, DependencyPathViewer, GlIntersperse },
      ...options,
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findPath = () => wrapper.find('[data-testid="dependency-path"]');
  const findPathLink = () => wrapper.findComponent(GlLink);
  const findPopover = () => wrapper.findComponent(GlPopover);

  it.each`
    name                      | location                    | path
    ${'container image path'} | ${Paths.containerImagePath} | ${Paths.containerImagePath.image}
    ${'no path'}              | ${Paths.noPath}             | ${Paths.noPath.path}
    ${'top level path'}       | ${Paths.topLevelPath}       | ${'package.json (top level)'}
    ${'short path'}           | ${Paths.shortPath}          | ${'package.json / swell 1.2 / emmajsq 10.11'}
    ${'long path'}            | ${Paths.longPath}           | ${'package.json / swell 1.2 / emmajsq 10.11 / 3 more'}
  `('shows dependency path for $name', ({ location, path }) => {
    createComponent({
      propsData: {
        location,
      },
    });

    expect(trimText(wrapper.text())).toContain(path);
  });

  describe('popover', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          location: Paths.longPath,
        },
      });
    });

    it('should render the popover', () => {
      expect(findPopover().exists()).toBe(true);
    });

    it('should have the complete path', () => {
      expect(trimText(findPopover().text())).toBe(
        'swell 1.2 / emmajsq 10.11 / zeb 12.1 / post 2.5 / core 1.0 There may be multiple paths',
      );
    });
  });

  describe('dependency with no dependency path', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          location: Paths.noPath,
        },
      });
    });

    it('should show the dependency name and link', () => {
      const locationLink = findPathLink();
      expect(locationLink.attributes().href).toBe('test.link');
      expect(locationLink.text()).toBe('package.json');
    });

    it('should not render dependency path', () => {
      const pathViewer = wrapper.findComponent(DependencyPathViewer);
      expect(pathViewer.exists()).toBe(false);
    });

    it('should not render the popover', () => {
      expect(findPopover().exists()).toBe(false);
    });

    it('should render the icon', () => {
      expect(findIcon().exists()).toBe(true);
    });
  });

  describe('dependency with container image dependency path', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          location: Paths.containerImagePath,
        },
      });
    });

    it('should render the dependency name not as a link without container-image: prefix', () => {
      expect(findPathLink().exists()).toBe(false);
      expect(findPath().text()).toBe(Paths.containerImagePath.image);
      expect(findPath().text()).not.toContain('container-image:');
    });

    it('should render the container-image icon', () => {
      const icon = findIcon();
      expect(icon.exists()).toBe(true);
      expect(icon.props('name')).toBe('container-image');
    });
  });
});
