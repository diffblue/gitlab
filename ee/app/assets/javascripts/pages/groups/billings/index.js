import { shouldQrtlyReconciliationMount } from 'ee/billings/qrtly_reconciliation';
import initSubscriptions from 'ee/billings/subscriptions';
import { shouldHandRaiseLeadButtonMount } from 'ee/hand_raise_leads/hand_raise_lead';
import PersistentUserCallout from '~/persistent_user_callout';

PersistentUserCallout.factory(document.querySelector('.js-gold-trial-callout'));
initSubscriptions();
shouldHandRaiseLeadButtonMount();
shouldQrtlyReconciliationMount();
