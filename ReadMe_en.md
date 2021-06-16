## Sample Login of DID based on TOPChain

**To illustrate and simplify the protocol, TOPChain acts as `Issuer` and `Identifier Registry` in this sample.**

### Experience address
[Sample Login of DID based on TOPChain](http://demo2.topnetwork.org/)

### DID Contract

This sample contract provides currently two interfaces.

#### Register DID:

```lua
function register_did(did)
    local account = tostring(exec_account())
    hset('mapdids', tostring(did), account)
end
```
Users could call the contract of `register_did` on their account and pass did with identifier of top. This builds a mapping between top account and outside readable identifier.

This function will save the did that passd by users as key and the `exec_account()` as value into the hash table of mapdids. In that case, `exec_account` could be used to get the current calling account, rather than pass in, mainly to ensure users could only build mapping on their own accounts.

#### Register Account Corresponding Properties :

```lua
function register_properties(properties)
    local account = tostring(exec_account())
    hset('mapproperties', account, tostring(properties))
end
```
Similarly, this function will save the `exec_account()` as key and any property information as value into the hash table of mapproperties.

### Proof of ID's ownership

In this sample, front-end acts as `Inspector-Verifier`, mainly to get some properties registered on the blockchain and verify the properties belongs to the same user.

Here we would use user's public key to verify the data signed by his private key, so that the user could be discovered whether is the ownership of this property. If a malicious user submit other user's did, the verifier would query the corresponding top account of this did and get the corresponding property and the public key included. The malicious user is required to encrypt the specified string by sha3, signed with his private key and verify with public key in the property. In that case, the malicious user would not succeed.

Is there a situation that a malicious user changes the public key of a normal user? It's impossible. The contrac interface in property ensures that any user could only write down his own property information. If the information `issuer` is third party, that requires to introduce the concept of trusted institutions registration, that is, to verify again the initiators.