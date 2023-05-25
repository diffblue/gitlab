import mountComponents from 'ee/registrations/groups/new';
import Group from '~/group';
import { trackCombinedGroupProjectForm, trackProjectImport } from '~/google_tag_manager';

// eslint-disable-next-line no-new
new Group();
mountComponents();
trackCombinedGroupProjectForm();
trackProjectImport();
