<img class="auther-icon" src="assets/icon.png" alt="Auther Icon" width="200" />

# Auther

Auther is a codeword generator inspired by TOTP authentication systems. It aims to protect against identity cloning scams.

1. **Exchange QR codes once**: When you're in-person with people close to you, exchange QR codes to register yourself on each other's device.
2. **Exchange codewords forever**: Then, when you chat remotely with that person, exchange codewords to verify each other's identity.

The codewords are generated using a secret passphrase that you set. Choose something easy to remember and hard to guess. 

Auther doesn't store any personal information or communicate with a server. It encodes your passphrase and forgets the unencoded version as soon as you enter it.

### Why does this app exist?

The age of zero-cost deepfakes is imminent.[[1]](https://arstechnica.com/information-technology/2024/04/microsofts-vasa-1-can-deepfake-a-person-with-one-photo-and-one-audio-track/)[[2]](https://arstechnica.com/information-technology/2024/08/new-ai-tool-enables-real-time-face-swapping-on-webcams-raising-fraud-concerns/)[[3]](https://arstechnica.com/information-technology/2023/01/microsofts-new-ai-can-simulate-anyones-voice-with-3-seconds-of-audio/) Some are already abusing this technology to run imposter scams.[[4]](https://arstechnica.com/information-technology/2024/04/alleged-ai-voice-imitation-leads-to-arrest-in-baltimore-school-racism-controversy/)[[5]](https://arstechnica.com/information-technology/2024/02/deepfake-scammer-walks-off-with-25-million-in-first-of-its-kind-ai-heist/)[[6]](https://www.cnn.com/2023/04/29/us/ai-scam-calls-kidnapping-cec/index.html) If you're reading this, you can probably sniff out a deepfake -- but can all your relatives and friends?

Using a single secret codeword may not be enough; if intercepted or guessed, your system is compromised. Auther provides a perpetual digital signature, so you and those close to you can communicate remotely with confidence.

### "Zero-cost deepfakes will turn out to be a non-issue."

If deepfake scam calls fizzle out of existence (or the vast majority of people become sensitive to them) and this entire project turns out to be in vain, I would be overjoyed.