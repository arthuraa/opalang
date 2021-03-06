/*
    Copyright © 2011, 2012 MLstate

    This file is part of Opa.

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * {1 About this module}
 *
 * This module contains a few encoding functions.
 *
 * {1 Where should I start ?}
 *
 * The documentation of this module is not complete. In particular, it could be nice
 * to get informations about in what condition such encoding are used, by who, for what reason, etc.
 *
 * {1 What if I need more ?}
 *
**/

/**
 * {1 Interface}
 */

import-plugin crypto

type Crypto.RSA.key = external

Crypto = {{

  Base64 = {{

    encode =  %% BslCrypto.base64_encode %% : binary -> string

    encode_compact =  %% BslCrypto.base64_encode_compact %% : binary -> string

    encode_multiline =  %% BslCrypto.base64_encode_multiline %% : binary -> string

    decode =  %% BslCrypto.base64_decode %% : string -> binary

    decode2 =  %% BslCrypto.base64_decode2 %% : string -> binary

  }}

  /**
   * The [HMAC] module implements keyed-hash functions (see the RFC2104).
   */
  HMAC = {{

    /**
     * A generic HMAC digest of the message [m].
     * @param H is the name of cryptographic hash function
     * @param K is a secret key
     * @param m is a message
     * @return the digest of [m]
     */
    @private
    digest(H, K, m) = %% BslCrypto.hmac_digest %%(H, K, m)

    /**
     * Calculates the HMAC-MD5 digest of [data] with the secret [key].
     * @param key is a secret key
     * @param data is a message
     * @return the calculated digest
     */
    md5(key, data) = digest("md5", key, data)

    /**
     * Calculates the HMAC-SHA1 digest of [data] with the secret [key].
     * @param key is a secret key
     * @param data is a message
     * @return the calculated digest
     */
    sha1(key, data) = digest("sha1", key, data)

    /**
     * Calculates the HMAC-SHA1 digest of [data] with the secret [key].
     * @param key is a secret key
     * @param data is a message
     * @return the calculated digest
     */
    sha256(key, data) = digest("sha256", key, data)

    /**
     * Calculates the HMAC-SHA1 digest of [data] with the secret [key].
     * @param key is a secret key
     * @param data is a message
     * @return the calculated digest
     */
    ripemd160(key, data) = digest("ripemd160", key, data)

  }}

  /**
   * The [Hash] module implements (unkeyed) hash functions.
   */
  Hash = {{

    /**
     * A generic digest of the message [m].
     * @param H is the name of cryptographic hash function
     * @param m is a message
     * @return the digest of [m]
     */
    @private
    digest(H, m) = %% BslCrypto.hash_digest %%(H, m)

    /**
     * Compute the MD5 signature of a string.
     *
     * @param data A text of arbitrary length.
     * @return A 32 digit long hexadecimal string
     */
    md5(data) = %%BslCrypto.md5%%(data)

    /**
     * Calculates the MD5 digest of [data].
     * @param data is a message
     * @return the calculated digest
     */
    md5_bin(data) = digest("md5", data)

    /**
     * Calculates the SHA1 digest of [data].
     * @param data is a message
     * @return the calculated digest
     */
    sha1(data) = digest("sha1", data)

    /**
     * Calculates the SHA256 digest of [data].
     * @param data is a message
     * @return the calculated digest
     */
    sha256(data) = digest("sha256", data)

    /**
     * Calculates the HMAC-RIPEM160 digest of [data].
     * @param data is a message
     * @return the calculated digest
     */
    ripemd160(data) = digest("ripemd160", data)

  }}

  #<Ifstatic:OPA_BACKEND_QMLJS>
  #<Else>
  RSA = {{

    /**
     * Generate a new RSA key of size [size].
     */
    new_key = %% BslCrypto.rsa_new_key %% : int -> Crypto.RSA.key

    /**
     * Encrypt a string with a certain RSA key.
     */
    encrypt = %% BslCrypto.rsa_encrypt %% : Crypto.RSA.key, string -> option(string)

    /**
     * Decrypt an RSA encrypted message.
     * /!\ You might need to trim the result in order to retrieve the origin message.
     */
    decrypt = %% BslCrypto.rsa_decrypt %% : Crypto.RSA.key, string -> option(string)

  }}
  #<End>

}}
