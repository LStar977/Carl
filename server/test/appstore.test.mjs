// Verifies the App Store JWS verification logic using a synthetic ES256 cert
// chain (root -> intermediate -> leaf) minted with openssl — proving the
// verifier accepts a genuine signature and rejects tampering / wrong root.
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import crypto, { X509Certificate } from 'node:crypto';
import { verifyTransaction, decodeJWSPayload, packIdFromProduct } from '../src/appstore.js';

const dir = mkdtempSync(join(tmpdir(), 'carl-certs-'));
const ssl = (args) => execFileSync('openssl', args, { cwd: dir, stdio: ['ignore', 'ignore', 'ignore'] });

function makeChain(prefix) {
  ssl(['ecparam', '-genkey', '-name', 'prime256v1', '-noout', '-out', `${prefix}root.key`]);
  ssl(['req', '-x509', '-new', '-key', `${prefix}root.key`, '-days', '3650', '-subj', `/CN=${prefix}Root`, '-out', `${prefix}root.pem`]);
  ssl(['ecparam', '-genkey', '-name', 'prime256v1', '-noout', '-out', `${prefix}int.key`]);
  ssl(['req', '-new', '-key', `${prefix}int.key`, '-subj', `/CN=${prefix}Int`, '-out', `${prefix}int.csr`]);
  ssl(['x509', '-req', '-in', `${prefix}int.csr`, '-CA', `${prefix}root.pem`, '-CAkey', `${prefix}root.key`, '-CAcreateserial', '-days', '3650', '-out', `${prefix}int.pem`]);
  ssl(['ecparam', '-genkey', '-name', 'prime256v1', '-noout', '-out', `${prefix}leaf.key`]);
  ssl(['req', '-new', '-key', `${prefix}leaf.key`, '-subj', `/CN=${prefix}Leaf`, '-out', `${prefix}leaf.csr`]);
  ssl(['x509', '-req', '-in', `${prefix}leaf.csr`, '-CA', `${prefix}int.pem`, '-CAkey', `${prefix}int.key`, '-CAcreateserial', '-days', '3650', '-out', `${prefix}leaf.pem`]);
  const der = (f) => new X509Certificate(readFileSync(join(dir, f))).raw.toString('base64');
  return {
    rootPEM: readFileSync(join(dir, `${prefix}root.pem`), 'utf8'),
    leafKey: crypto.createPrivateKey(readFileSync(join(dir, `${prefix}leaf.key`))),
    x5c: [der(`${prefix}leaf.pem`), der(`${prefix}int.pem`), der(`${prefix}root.pem`)],
  };
}

const b64url = (buf) => Buffer.from(buf).toString('base64url');

function signJWS(payload, chain) {
  const header = { alg: 'ES256', x5c: chain.x5c };
  const input = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(payload))}`;
  const sig = crypto.sign('sha256', Buffer.from(input), { key: chain.leafKey, dsaEncoding: 'ieee-p1363' });
  return `${input}.${b64url(sig)}`;
}

let passed = 0, failed = 0;
const check = (name, cond, extra = '') => cond ? (passed++, console.log(`  ✓ ${name}`)) : (failed++, console.log(`  ✗ ${name} ${extra}`));
const throws = (fn) => { try { fn(); return false; } catch { return true; } };

console.log('\nApp Store receipt verification');
const chain = makeChain('a');
const other = makeChain('b');
const bundleId = 'com.carlapp.Carl';
const payload = { bundleId, productId: 'com.carlapp.credits.popular', transactionId: 'tx-0001', environment: 'Sandbox' };
const jws = signJWS(payload, chain);

const verified = verifyTransaction(jws, { rootCertPEM: chain.rootPEM, bundleId });
check('verifies a genuine signed transaction', verified.transactionId === 'tx-0001');
check('extracts the productId', verified.productId === 'com.carlapp.credits.popular');
check('maps product → pack', packIdFromProduct(verified.productId) === 'popular');

check('rejects a tampered payload', throws(() => {
  const parts = jws.split('.');
  const bad = { ...payload, productId: 'com.carlapp.credits.pro' };
  verifyTransaction(`${parts[0]}.${b64url(JSON.stringify(bad))}.${parts[2]}`, { rootCertPEM: chain.rootPEM, bundleId });
}));

check('rejects an untrusted root', throws(() =>
  verifyTransaction(jws, { rootCertPEM: other.rootPEM, bundleId })));

check('rejects a bundle mismatch', throws(() =>
  verifyTransaction(jws, { rootCertPEM: chain.rootPEM, bundleId: 'com.someoneelse.app' })));

check('rejects when no root anchor provided', throws(() =>
  verifyTransaction(jws, { rootCertPEM: '', bundleId })));

check('decodeJWSPayload reads without verifying', decodeJWSPayload(jws)?.transactionId === 'tx-0001');

console.log(`\n${failed === 0 ? '✅' : '❌'} ${passed} passed, ${failed} failed\n`);
process.exit(failed === 0 ? 0 : 1);
