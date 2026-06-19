// Credits = applications. A credit is consumed only when Carl actually submits.
import { store } from '../store.js';
import { nowISO, uid } from '../util.js';

export const PACKS = [
  { id: 'starter', name: 'Starter', credits: 25, applications: 25, price: 1900, priceText: '$19' },
  { id: 'popular', name: 'Popular', credits: 100, applications: 110, bonus: 10, price: 5900, priceText: '$59' },
  { id: 'pro', name: 'Pro', credits: 300, applications: 340, bonus: 40, price: 14900, priceText: '$149' },
];

export function balance(user) { return user.credits || 0; }

export function consume(user, n = 1) {
  if ((user.credits || 0) < n) return false;
  user.credits -= n;
  store.updateUser(user);
  store.addTx(user.id, { id: uid('tx'), type: 'consume', amount: -n, at: nowISO() });
  return true;
}

export function grant(user, n, meta = {}) {
  user.credits = (user.credits || 0) + n;
  store.updateUser(user);
  store.addTx(user.id, { id: uid('tx'), type: 'grant', amount: n, at: nowISO(), ...meta });
  return user.credits;
}

/**
 * Apply a purchase. In production, `receipt` must be validated with Apple's
 * App Store server API before granting. Here we validate the pack and grant.
 */
export function purchase(user, packId /*, receipt */) {
  const pack = PACKS.find((p) => p.id === packId);
  if (!pack) return { ok: false, error: 'unknown_pack' };
  // TODO: validate StoreKit `receipt` with Apple before granting.
  const total = pack.credits + (pack.bonus || 0);
  const newBalance = grant(user, total, { type: 'purchase', packId, price: pack.price });
  return { ok: true, granted: total, balance: newBalance, pack };
}
