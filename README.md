<img class="auther-icon" src="assets/icon.png" alt="Auther Icon" width="200" />

# Auther

Auther is a codeword generator inspired by TOTP authentication systems. It aims to protect against identity cloning scams.

1. **Exchange QR codes once**: When you're in-person with people close to you, exchange QR codes to register yourself on each other's device.
2. **Exchange codewords forever**: Then, when you chat remotely with that person, exchange codewords to verify each other's identity.

The codewords are generated using a secret passphrase that you set. Choose something easy to remember and hard to guess. 

Auther doesn't store any personal information or communicate with a server. It encodes your passphrase and forgets the unencoded version as soon as you enter it.

### Why does this app exist?

1. The age of zero-cost deepfakes is imminent. 
2. Some are already abusing this technology to run imposter scams. 
For an ongoing chronicle of evidence for both of these points, [please see this page.](https://bgsulz.com/auther/) 

If you're reading this, you can probably sniff out a deepfake -- but can all your relatives and friends?

Using a single secret codeword may not be enough; if intercepted or guessed, your system is compromised. Auther provides a perpetual digital signature, so you and those close to you can communicate remotely with confidence.

### "Zero-cost deepfakes will turn out to be a non-issue."

If deepfake scam calls fizzle out of existence (or the vast majority of people become sensitive to them) and this entire project turns out to be in vain, I would be overjoyed.