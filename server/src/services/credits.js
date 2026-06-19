// Credits = applications. A credit is consumed only when Carl actually submits.
import { store } from '../store.js';
import { config } from '../config.js';
import { nowISO, uid } from '../util.js';
import { verifyTransaction, decodeJWSPayload, packIdFromProduct } from '../appstore.js';

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
 * Apply a purchase. `receipt` is the StoreKit 2 signed transaction JWS.
 * When APPSTORE_VERIFY=on we cryptographically verify it against Apple's root,
 * derive the pack from the verified productId, and guard against replay by
 * transactionId. In dev (verify off) we trust the client but still read the
 * product/transaction from the JWS when present.
 */
export async function purchase(user, packId, receipt) {
  let resolvedPackId = packId;
  let transactionId = null;

  const looksLikeJWS = receipt && String(receipt).split('.').length === 3;
  if (looksLikeJWS) {
    if (config.appstoreVerify === 'on') {
      let payload;
      try {
        payload = verifyTransaction(receipt, {
          rootCertPEM: config.appleRootCert,
          bundleId: config.appleBundleId,
        });
      } catch (e) {
        return { ok: false, error: 'receipt_invalid', detail: String(e.message) };
      }
      resolvedPackId = packIdFromProduct(payload.productId) || packId;
      transactionId = payload.transactionId;
    } else {
      const payload = decodeJWSPayload(receipt);
      if (payload) {
        resolvedPackId = packIdFromProduct(payload.productId) || packId;
        transactionId = payload.transactionId;
      }
    }
  } else if (config.appstoreVerify === 'on') {
    // In production a receipt is required.
    return { ok: false, error: 'receipt_required' };
  }

  if (transactionId && !store.useTransaction(transactionId)) {
    return { ok: false, error: 'duplicate_transaction' };
  }

  const pack = PACKS.find((p) => p.id === resolvedPackId);
  if (!pack) return { ok: false, error: 'unknown_pack' };

  const total = pack.credits + (pack.bonus || 0);
  const newBalance = grant(user, total, { type: 'purchase', packId: pack.id, price: pack.price, transactionId });
  return { ok: true, granted: total, balance: newBalance, pack };
}
