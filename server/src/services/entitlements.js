// Non-consumable entitlements (one-time unlocks), e.g. the résumé builder.
// Mirrors the credits purchase flow: verify the StoreKit 2 JWS when
// APPSTORE_VERIFY=on, dedupe by transactionId, then grant the entitlement.
import { store } from '../store.js';
import { config } from '../config.js';
import { verifyTransaction, decodeJWSPayload } from '../appstore.js';

export const PRODUCTS = [
  { id: 'com.carlapp.resumebuilder', entitlement: 'resumeBuilder', price: 1499, priceText: '$14.99' },
];

export function hasEntitlement(user, key) {
  return (user.entitlements || []).includes(key);
}

export async function purchaseEntitlement(user, productId, receipt) {
  let resolvedProductId = productId;
  let transactionId = null;

  const looksLikeJWS = receipt && String(receipt).split('.').length === 3;
  if (looksLikeJWS) {
    if (config.appstoreVerify === 'on') {
      let payload;
      try {
        payload = verifyTransaction(receipt, { rootCertPEM: config.appleRootCert, bundleId: config.appleBundleId });
      } catch (e) {
        return { ok: false, error: 'receipt_invalid', detail: String(e.message) };
      }
      resolvedProductId = payload.productId || productId;
      transactionId = payload.transactionId;
    } else {
      const payload = decodeJWSPayload(receipt);
      if (payload) { resolvedProductId = payload.productId || productId; transactionId = payload.transactionId; }
    }
  } else if (config.appstoreVerify === 'on') {
    return { ok: false, error: 'receipt_required' };
  }

  if (transactionId && !store.useTransaction(transactionId)) {
    return { ok: false, error: 'duplicate_transaction' };
  }

  const product = PRODUCTS.find((p) => p.id === resolvedProductId);
  if (!product) return { ok: false, error: 'unknown_product' };

  const set = new Set(user.entitlements || []);
  set.add(product.entitlement);
  user.entitlements = [...set];
  store.updateUser(user);
  return { ok: true, entitlement: product.entitlement, entitlements: user.entitlements };
}
