// App Store (StoreKit 2) signed-transaction verification.
//
// StoreKit 2 hands the app a JWS (`Transaction.jwsRepresentation`) signed by
// Apple. We verify it server-side WITHOUT any API key: parse the JWS, validate
// the x5c certificate chain up to Apple's root, check the signature, then trust
// the payload (bundleId, productId, transactionId…).
//
// Note: local StoreKit testing in the simulator signs with a *local* test cert,
// not Apple's root — so enforced verification is for Sandbox/Production
// (TestFlight + App Store), where Apple signs with the real chain.
import crypto, { X509Certificate } from 'node:crypto';

/** Decode the JWS payload without verifying (used in dev/no-verify mode). */
export function decodeJWSPayload(jws) {
  const parts = String(jws).split('.');
  if (parts.length !== 3) return null;
  try {
    return JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
  } catch {
    return null;
  }
}

/**
 * Verify a signed transaction JWS against a trusted root certificate.
 * @returns the decoded payload on success; throws Error(reason) otherwise.
 */
export function verifyTransaction(jws, { rootCertPEM, bundleId }) {
  const parts = String(jws).split('.');
  if (parts.length !== 3) throw new Error('not_a_jws');
  const [h, p, s] = parts;

  const header = JSON.parse(Buffer.from(h, 'base64url').toString('utf8'));
  if (header.alg !== 'ES256') throw new Error('bad_alg');
  const x5c = header.x5c;
  if (!Array.isArray(x5c) || x5c.length < 2) throw new Error('no_cert_chain');

  const chain = x5c.map((c) => new X509Certificate(Buffer.from(c, 'base64')));
  const leaf = chain[0];

  // Each cert must be signed by the next one up the chain.
  for (let i = 0; i < chain.length - 1; i++) {
    if (!chain[i].verify(chain[i + 1].publicKey)) throw new Error('chain_link_invalid');
  }

  // Validity windows.
  const now = Date.now();
  for (const cert of chain) {
    if (now < Date.parse(cert.validFrom) || now > Date.parse(cert.validTo)) {
      throw new Error('cert_not_valid_now');
    }
  }

  // Anchor to the trusted Apple root.
  if (!rootCertPEM) throw new Error('no_root_anchor');
  const trusted = new X509Certificate(rootCertPEM);
  const top = chain[chain.length - 1];
  if (top.fingerprint256 === trusted.fingerprint256) {
    // root is included in the chain and matches our anchor
  } else if (!top.verify(trusted.publicKey)) {
    throw new Error('untrusted_root');
  }

  // Verify the JWS signature (ES256 = raw r||s, IEEE P1363).
  const signingInput = Buffer.from(`${h}.${p}`);
  const signature = Buffer.from(s, 'base64url');
  const ok = crypto.verify(
    'sha256', signingInput,
    { key: leaf.publicKey, dsaEncoding: 'ieee-p1363' },
    signature
  );
  if (!ok) throw new Error('signature_invalid');

  const payload = JSON.parse(Buffer.from(p, 'base64url').toString('utf8'));
  if (bundleId && payload.bundleId && payload.bundleId !== bundleId) {
    throw new Error('bundle_mismatch');
  }
  return payload;
}

/** Map an IAP product id (`com.carlapp.credits.<pack>`) to a pack id. */
export function packIdFromProduct(productId) {
  const m = String(productId || '').match(/credits\.(\w+)$/);
  return m ? m[1] : null;
}
