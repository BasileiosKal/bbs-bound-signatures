%%%
title = "Bound BBS Signatures"
abbrev = "Bound BBS Signatures"
ipr= "none"
area = "General"
workgroup = "none"

[seriesInfo]
name = "Individual-Draft"
value = "draft-bound-bbs-signatures-latest"
status = "informational"

[[author]]
initials = "V."
surname = "Kalos"
fullname = "Vasilis Kalos"
#role = "editor"
organization = "MATTR"
  [author.address]
  email = "vasilis.kalos@mattr.global"

%%%

.# Abstract

In the bound BBS Signatures scheme, the Signer of the BBS signature binds it to a BLS secret key holded by the Prover. Creating a valid BBS Proof from that signature, will require knowledge of that secret key.

{mainmatter}

# Introduction

Creating a BBS signature bound to a Prover's secret, follows a very similar flow and procedure as then normal BBS Signature and Proof generation and verification flow. The main deference is that the Prover is required to supply a BLS public key, together with a proof of possession (KeyPoP) of the corresponding secret key, prior to issuance of the bound BBS signature. The flow for issuing and using a bound BBS signature can be seen bellow.

!---
~~~ ascii-art
(3) BoundSign                           (1) BlsKeyPoP
   +-----                                   +-----
   |    |                                   |    |
   |    |                                   |    |
   |   \ /                                  |   \ /
+----------+                             +-----------+
|          |                             |           |
|          |                             |           |
|          |<----(2) send PK, KeyPoP-----|           |---+
|  Signer  |                             |  Holder/  |   | (5) BoundProofGen
|          |--(4) Send signature + msgs->|  Prover   |<--|
|          |                             |           |
|          |                             |           |
+----------+                             +-----------+
                                               |
                                               |
                                               |
                                 (6) Send proof + disclosed msgs
                                               |
                                               |
                                              \ /
                                         +-----------+
                                         |           |
                                         |           |
                                         |           |
                                         | Verifier  |
                                         |           |
                                         |           |
                                         |           |
                                         +-----------+
                                            |   / \
                                            |    |
                                            |    |
                                            +-----
                                    (7) BoundProofVerify


~~~
!---
Figure: Basic diagram capturing the main entities involved in using the scheme

## Notation

- BP_1
  : The base point of the G1 subgroup.
- list.push(element)
  : push an element, to the end of a list.
- BlsSign, BlsVerify
  : BLS Signatures Sign and Verify operations, in "message augmentation" mode, as described in Section 3.2.1 of [@!I-D.irtf-cfrg-bls-signature].


## BBS operations
This document makes use of various operations defined in the BBS draft [@!I-D.irtf-cfrg-bbs-signatures]. Note that the Core BBS operations used (i.e., BbsVerify, BbsProofGen and BbsProofVerify) are using the create_generators procedure defined in this document in [Create Generators](#create-generators), instead of the one defined in the BBS document (which we wil denote as core\_create\_generators here). More specifically,

- core\_create\_generators := create\_generators as defined in [Section 4.2](https://www.ietf.org/archive/id/draft-irtf-cfrg-bbs-signatures-02.html#name-generator-point-computation) in [@!I-D.irtf-cfrg-bbs-signatures]
- BbsVerify := Verify as defined in [Section 3.4.2](https://www.ietf.org/archive/id/draft-irtf-cfrg-bbs-signatures-02.html#name-verify) in [@!I-D.irtf-cfrg-bbs-signatures], using the create\_generators procedure as defined in [Create Generators](#create-generators).
- BbsProofGen := ProofGen as defined in [Section 3.4.3](https://www.ietf.org/archive/id/draft-irtf-cfrg-bbs-signatures-02.html#name-proofgen) in [@!I-D.irtf-cfrg-bbs-signatures], using the create\_generators procedure as defined in [Create Generators](#create-generators).
- BbsProofVerify := ProofVerify as defined in [Section 3.4.4](https://www.ietf.org/archive/id/draft-irtf-cfrg-bbs-signatures-02.html#name-proofverify) in [@!I-D.irtf-cfrg-bbs-signatures], using the create\_generators procedure as defined in [Create Generators](#create-generators).

## BBS and BLS Ciphersuites

This document requires the use of both a BBS and a BLS ciphersuite. Those ciphersuites MUST be based on the same curves (i.e., BLS12-381, BN etc). Additionally, the BLS ciphersuite, MUST use a "message augmentation" ciphersuite, with "minimal-pubkey-size". As an example of a BBS and BLS suites that can be used together are the following:
```
BBS Suite: "BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_"
BLS Suite: "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_AUG_"
```

The BBS Signer MUST validate that the correct BLS ciphersuite is used. This is done by performing the necessary subgroup checks (see the [Subgroup Checks](#subgroup-checks) section).

# Prover's Set Up

The prover must create a BLS secret/public key pair and supply proof of possessing (PoP) the BLS secret key, as well as that the public key is well formed. This is achieved by creating a BLS signature, using that secret key, and sending that signature to the Issuer.

The BLS suite used MUST be based to the same curves as the BBS suite (i.e., BLS12-381). The BLS suite MUST also use a signature variant for minimum public key size (SV: minimal-pubkey-size).

## BLS keys generation

```
BlsSk = Bls_KeyGen(IKM)
BlsPk = BlsSkToPk(SK)
```

## BLS secret key commitment

The BlsKeyPoP operation is used by the Prover to generate a proof of possession of their BLS secret key. The commitment is essentially a BLS signature to a predefined message. NOTE: The BlsSign bellow is NOT BLS core sign, but rather the "message augmentation" Sign. See the [Notation](#notation) section.

The BLS signature is calculated over a message including both the BBS and BLS ciphersuites, an audience identifier (i.e., the BBS Signer's ID), a domain separation tag (dst) and any extra information the application may require to be bound to a proof (like a BBS Signer's supplied nonce, a creation date etc.).

Although the dst is optional, it is RECOMMENDED that it will include at least the application's name together with a version number.

```
KeyPoP = BlsKeyPoP(BlsSk, aud, extra_info, dst)

Inputs:

- BlsSk (REQUIRED), octet string. The BLS secret key
- aud (REQUIRED), octet string. The Issuer's unique identifier.
- dst (OPTIONAL), octet string. Domain separation tag. If not supplied
                  it defaults to the empty string ("").
- extra_info (OPTIONAL), octet string. Extra information to bind to a
                         KeyPoP (e.g., creation date, dst etc.). If not
                         supplied, it defaults to the empty string ("").

Parameters:

- bbs_suite_id, ASCII string. The unique ID of the BBS ciphersuite.
- bls_suite_id, ASCII string. The unique ID of the BLS ciphersuite.

Outputs:

- KeyPoP, octet string. A BLS signature, representing the commitment
                to the secret key.

Procedure:

1. msg = get_bls_pop_msg(bbs_suite_id, bls_suite_id, aud, dst, extra_info)
2. if msg is INVALID, return INVALID
3. Bls_Signature = BlsSign(BlsSk, msg)
4. return Bls_Signature
```

# Core Operations

## Signature Generation

A bound BBS signature issuance consists of 2 steps. First, the public key and PoP supplied by the prover are validated. Then, that PK is used to generate the BBS signature. Both operations are further explained bellow,

### BLS Key PoP Verification

The BlsKeyPopVerify operation validates a proof of possession of a BLS secret key (KeyPoP) created using the [BlsKeyPoP](#bls-secret-key-commitment) operation. It is used from the Signer to validate the KeyPoP supplied by the Prover, against the Prover's BLS public key. This operation MUST at all times proceed the Bound BBS signature generation procedure. The signer MUST NOT create a bound BBS signature if the BlsKeyPopVerify operation does not return VALID first.

```
result = BlsKeyPopVerify(KeyPoP, BlsPk, aud, dst, extra_info)

Inputs

- KeyPoP (REQUIRED), octet string. The key commitment outputted
                            from the BlsKeyPoP operation.
- BlsPk (REQUIRED), octet string. The Prover's BLS public key.
- aud (REQUIRED), octet string. The Issuer's unique identifier.
- dst (OPTIONAL), octet string. Domain separation tag. If not supplied
                  it defaults to the empty string ("").
- extra_info (OPTIONAL), octet string. Extra information bound to the
                         KeyPoP (e.g., creation date etc.). If not
                         supplied it defaults to the empty string ("").

Parameters:

- bbs_suite_id, ASCII string. The unique ID of the BBS ciphersuite.
- bls_suite_id, ASCII string. The unique ID of the BLS ciphersuite.

Procedure:

1. res = KeyValidate(BlsPk)
2. if res INVALID, return INVALID

3. msg = get_bls_pop_msg(bbs_suite_id, bls_suite_id, aud, dst, extra_info)
4. if msg is INVALID, return INVALID

5. res = BlsVerify(BlsPk, msg, KeyPoP)
6. if res is INVALID, return INVALID

7. return VALID
```

### Signature Issuance

The BoundSign operation is used by the signer to return a valid BBS signature, including the Prover's BLS secret key as one of signed messages. It works exactly like the regular BBS Sign, but it adds the BlsPk to the value of B. The Signer MUST first validate the correctness of the Prover's Bls PK, using the [BlsKeyPopVerify](#bls-key-pop-verification) operation.

```
boundBbsSignature = BoundSign(SK, PK, BlsPk, header, messages)

Inputs:

// SK, PK, header and messages, are as in the BBS draft spec.
- BlsPk (REQUIRED), octet string. The Prover's BLS public key.

Parameters:

- bbs_suite_id, ASCII string. The unique ID of the BBS ciphersuite.
- BP_1, the base point of G1, defined by the BLS ciphersuite.

Procedure:

1.  res = KeyValidate(BlsPk)
2.  if res INVALID, return INVALID

//  Bond BBS specific header
3.  header_prime = header || "BBS_BOUND_"

//  Calculate the domain, also including the base point of G1
4.  (Q_1, Q_2, H_1, ..., H_L) = core_create_generators(L+2)
5.  domain = calculate_domain(PK, Q_1, Q_2, (H_1, ..., H_L, BP_1), header)
6.  if domain is INVALID, return INVALID

//  e, s calculation, also including the BlsPk received from the Prover
7.  e_s_octs = serialize((SK, BlsPk, domain, msg_1, ..., msg_L))
8.  if e_s_octs is INVALID, return INVALID
9.  e_s_len = octet_scalar_length * 2
10. e_s_expand = expand_message(e_s_octs, expand_dst, e_s_len)
11. if e_s_expand is INVALID, return INVALID
12. e = hash_to_scalar(e_s_expand[0..(octet_scalar_length - 1)])
13. s = hash_to_scalar(e_s_expand[octet_scalar_length..(e_s_len - 1)])
14. if e or s is INVALID, return INVALID

//  Use the BlsPk to calculate B
15. B = P1 + Q_1 * s + Q_2 * domain + H_1 * msg_1 + ... + H_L * msg_L
16. B = B + BlsPk

17. A = B * (1 / (SK + e))
18. return signature_to_octets(A, e, s)
```

## Signature Verification

Bound signature verification is used by the Prover to validate the signature returned from the Signer. The operation is mostly the same as BBSVerify, with the difference that the prover's BLS secret key is included as one of the messages, and that the create\_generators used is the one defined in [Create Generators](#create-generators).
```
result = BoundVerify(PK, BlsSk, signature, header, messages)

Inputs:

// PK, signature, header, messages are the same as in the BBS draft
- BlsSk (REQUIRED), octet string, the Prover's BLS secret key.

Parameters:

- BP_1, the base point of G1, defined by the BLS ciphersuite.

Procedure:

1. messages.push(BlsSk)
2. header_prime = header || "BBS_BOUND_"
3. result = BbsVerify(PK, signature, header_prime, messages)
4. if result is INVALID, return INVALID
5. return VALID
```

## Proof Generation

The BoundProofGen operation, is used by the Prover to create a proof bound to their BLS secret key. The operation has the same Procedure as the normal BBS ProofGen operation, with the difference that the BlsSk of the prover is included as one of (undisclosed) the messages, and that the create\_generators used is the one defined in [Create Generators](#create-generators).

```
proof = BoundProofGen(PK, signature, BlsSk, header, ph, messages,
                                                     disclosed_indexes)

Inputs:

// PK, signature, header, ph, messages, and disclosed_indexes are the
// same as in the BBS draft spec
- BlsSk (REQUIRED), octet string, the Prover's BLS secret key.

Parameters:

- BP_1, the base point of G1, defined by the BLS ciphersuite.

Procedure:

1. messages.push(BlsSk)
2. header_prime = header || "BBS_BOUND_"
3. proof = BBSProofGen(PK, signature, header_prime, ph, messages,
                                                     disclosed_indexes)
4. if proof is INVALID, return INVALID
5. return proof
```

## Proof Verification

The BoundProofVerify operation is used to validate the bound proof. The operation is essentially using the BbsVerify from BBS draft, with the only difference the use of the create\_generators procedure defined in [Create Generators](#create-generators)). Note: the Preconditions steps are also updated, to apply in the case of Bound BBS signatures.

```
result = BoundProofVerify(PK, proof, L, header, ph,
                     disclosed_messages,
                     disclosed_indexes)

Inputs:
// PK, proof, L, header, ph, disclosed_messages, disclosed_indexes the
// same as in the BBS draft spec.

Parameters:
// The same as in the BBS draft spec with one addition
- BP_1, the base point of G1, defined by the BLS ciphersuite.

Definitions:
// The same as in the BBS draft spec

Outputs:
// The same as in the BBS draft spec

Preconditions:
// L was updated to L + 1.
1. for i in (i1, ..., iR), if i < 1 or i > L - 1, return INVALID
2. if length(disclosed_messages) != R, return INVALID

Procedure:

1. header_prime = header || "BBS_BOUND_"
2. result = BbsProofVerify(PK, proof, header_prime, ph, 
                                 disclosed_messages, disclosed_indexes)
3. if result is INVALID, return INVALID
4. return VALID
```

# Utility Operations

## GetBlsPopMsg

Returns the message that the prover will sign to demonstrate possession of a BLS secret key. The message includes the BBS and BLS ciphersuite identifiers, the audience (aud) of the PoP (i.e., the Issuer's) unique identifier, a domain separation tag (dst), as well as any extra information (like creation date, random nonces etc), the application may require. It is RECOMMENDED to include the BLS PK of the prover, as part of the extra information (extra_info) signed.

```
msg = get_bls_pop_msg(bbs_suite_id, bls_suite_id, aud, extra_info, dst)

Inputs:
- bbs_suite_id (REQUIRED), ASCII string. The unique ID of the BBS ciphersuite.
- bls_suite_id (REQUIRED), ASCII string. The unique ID of the BLS ciphersuite.
- aud (REQUIRED), octet string. The unique ID of the Issuer.
- dst (OPTIONAL), octet string. Domain separation tag. If not supplied
                  it defaults to the empty string ("").
- extra_info (OPTIONAL), octet string. Extra information to include to the
                       message. If not supplied, it defaults to the
                       empty string ("").

Outputs:

- msg, octet string or INVALID.

Procedure:

1. aud_len = length(Aud)
2. extra_info_len = length(extra_info)
3. if aud_len > 65535 or extra_info_len > 65535, return INVALID
4. if length(dst) > 255, return INVALID

5. msg_prime = utf8(bbs_suite_id) || utf8(bls_suite_id)
6. msg_prime = msg_prime || utf8("BBS_BLS_POP_MSG_")
7. msg_prime = msg_prime || I2OSP(aud_len, 2) || aud 
8. msg = msg_prime || I20SP(extra_info_len, 2) || extra_info || dst
9. return msg
```

## Create Generators
An updated create\_generators procedure, that also returns the base point of G1 as the last generator. This create\_generators operation should be used in place of the one described in [Section 4.2](https://www.ietf.org/archive/id/draft-irtf-cfrg-bbs-signatures-02.html#name-generator-point-computation) in the BBS draft, when using the core BBS operations.

```
generators = create_generators(count)

Inputs:

- count (REQUIRED), unsigned integer. Number of generators to create.

Outputs:

- generators, an array of count generators.

Procedure:

1. if count < 1, return INVALID
2. generators = core_create_generators(count - 1)
3. if generators is INVALID, return INVALID
4. (generator_1, ..., generator_(count-1)) = generators
5. return (generator_1, ..., generator_(count-1), BP_1)
```

# Security Considerations

## Subgroup Checks

There are 2 relative subgroup checks that need to be performed: First that the BLS KeyPoP is a valid point of G2 and second that the BLS PK is a valid point of G1.

The BLS KeyPoP check is done internally during BlsVerify step of the [BlsKeyPopVerify](#bls-key-pop-verification) operation, which calls the `signature_subgroup_check` utility operation. Although some implementations of BLS signatures don't include that check, it MUST NOT be skipped. If the BLS implementation does not include it, the BBS Signer MUST add it as a pre-computation step in the BlsKeyPopVerify operation. It's also important that this check is performed for the correct subgroup i.e., for G2.

Similarly, the BLS public key of the Prover, MUST be a valid point of G1. This is checked using `KeyValidate` in the first step of [BlsKeyPopVerify](#bls-key-pop-verification). This step is REQUIRED and must not be skipped. This not only for the BlsVerify operation to be well defined, but also that the public key can be used to bind the BBS signature to the BLS secret key of the Prover. It's also important that this check is performed for the correct subgroup i.e., for G1.

## Key PoP Domain Separation

It is RECOMMENDED that proper domain separation will be used when creating a KeyPoP using the [BlsKeyPoP](#bls-secret-key-commitment) operation. A proper dst value includes at least the name of the application and a version number. This is critical when new versions of this draft and the api are released that mitigate issues and vulnerabilities. See Section 3.1 from [@I-D.irtf-cfrg-hash-to-curve] for more details.

## Key PoP Uniqueness

The BlsSign used to generate the KeyPoP during the [BlsKeyPoP](#bls-secret-key-commitment) is deterministic and hence constant on the same inputs. As a result, other mechanisms are needed to guarantee the uniqueness of the KeyPoP returned by that operation. It is RECOMMENDED that the BBS Signer will take steps to validate the uniqueness and freshness of the KeyPoP received from the Prover. Those steps include but are not limited to: inserting a random nonce (supplied by the Signer) or the creation date, as part of the `extra_info` input field of the [BlsKeyPoP](#bls-secret-key-commitment) operation.

{backmatter}
