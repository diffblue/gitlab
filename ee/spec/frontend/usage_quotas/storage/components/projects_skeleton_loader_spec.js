import { mount } from '@vue/test-utils';
import ProjectsSkeletonLoader from 'ee/usage_quotas/storage/components/projects_skeleton_loader.vue';

describe('ProjectsSkeletonLoader', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(ProjectsSkeletonLoader, {
      propsData: {
        ...props,
      },
    });
  };

  const findDesktopLoader = () => wrapper.find('[data-testid="desktop-loader"]');
  const findMobileLoader = () => wrapper.find('[data-testid="mobile-loader"]');

  beforeEach(createComponent);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('desktop loader', () => {
    it('produces 5 rows', () => {
      expect(findDesktopLoader().findAll('rect[width="1000"]')).toHaveLength(5);
    });

    it('has the correct classes', () => {
      expect(findDesktopLoader().classes()).toEqual([
        'gl-display-none',
        'gl-md-display-flex',
        'gl-flex-direction-column',
      ]);
    });
  });

  describe('mobile loader', () => {
    it('produces 5 rows', () => {
      expect(findMobileLoader().findAll('rect[height="110"]')).toHaveLength(5);
    });

    it('has the correct classes', () => {
      expect(findMobileLoader().classes()).toEqual([
        'gl-flex-direction-column',
        'gl-md-display-none',
      ]);
    });
  });
});
