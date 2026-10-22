# UForm resource budget

UForm's small paired retrieval model adds roughly **61 MB of neural-optimized model/tokenizer files** if both encoders are provisioned. The keyboard would need only the query text encoder, roughly **39 MB of those files**, after image embeddings are precomputed elsewhere. Neither number establishes RAM, startup time or keyboard viability. Keep this candidate outside the keyboard cold path until real-device measurements justify integration.

Checked 23 October 2026. No weights were downloaded, models installed, app logic changed or media scope approved. This note measures public artifact metadata and inspects source; it does not contain inference or app-size benchmarks.

## Exact checkpoint files

Model: `unum-cloud/uform3-image-text-english-small`, pinned revision `a8d990ed0dc6340b9c25cb47f06f86b9ecb67fa6`. The file-tree API was checked directly. Totals below include each package's graph/manifest and weight file. Decimal MB = 1,000,000 bytes. [Pinned file tree](https://huggingface.co/unum-cloud/uform3-image-text-english-small/tree/a8d990ed0dc6340b9c25cb47f06f86b9ecb67fa6), [metadata API](https://huggingface.co/api/models/unum-cloud/uform3-image-text-english-small/tree/a8d990ed0dc6340b9c25cb47f06f86b9ecb67fa6?recursive=true&expand=false).

| Artifact | Bytes | MB |
| --- | ---: | ---: |
| `text_encoder_neural.mlpackage/` | 38,091,521 | 38.092 |
| `image_encoder_neural.mlpackage/` | 22,318,188 | 22.318 |
| `text_encoder.mlpackage/` | 151,481,669 | 151.482 |
| `image_encoder.mlpackage/` | 87,218,431 | 87.218 |
| `tokenizer.json` | 710,348 | 0.710 |
| `config.json` | 923 | 0.001 |

Both neural packages plus metadata total **61,120,980 bytes (61.121 MB / 58.29 MiB)**. Neural query text plus metadata totals **38,802,792 bytes (38.803 MB / 37.01 MiB)**. Both ordinary packages plus metadata total **239,411,371 bytes (239.411 MB / 228.32 MiB)**. The earlier report's 22.1/38.0 MB figures described weight files alone; package totals explain the difference.

The model card specifies 256-dimensional embeddings, a 64-token text context and 224 × 224 images. The checkpoint declares Apache-2.0. It is an English retrieval model. UForm's larger generative chat/captioning models are separate downloads: the repository's “1B Parameter Chat” headline does not describe this paired retrieval checkpoint. [Small model card](https://huggingface.co/unum-cloud/uform3-image-text-english-small/blob/a8d990ed0dc6340b9c25cb47f06f86b9ecb67fa6/README.md), [configuration](https://huggingface.co/unum-cloud/uform3-image-text-english-small/blob/a8d990ed0dc6340b9c25cb47f06f86b9ecb67fa6/config.json), [separate model families](https://github.com/unum-cloud/UForm/blob/f4beec53743b44ffaad4ff754d65f6c2d347bbd9/README.md#models).

## Swift defaults can select the larger artifact

Upstream HEAD remains `f4beec53743b44ffaad4ff754d65f6c2d347bbd9` when checked today. In `swift/Encoders.swift`:

- `TextEncoder(modelName:computeUnits:)` and `ImageEncoder(modelName:computeUnits:)` default to `.all`. Their filename selection therefore chooses the **ordinary** package.
- Explicit `.cpuAndNeuralEngine` selects the corresponding `*_neural.mlpackage`. The two convenience constructors instantiate their respective encoders separately; constructing text alone does not require loading image.
- `modelPath:` constructors load the exact supplied artifact. Changing compute units does not change the local filename or quantize weights. Pass explicit config/tokenizer paths when those files sit beside the model package; defaults append them inside `modelPath`.
- The loader calls Core ML compilation for uncompiled packages, then loads `MLModel`. Compilation, cold loading and tokenizer initialization must be budgeted separately from warm prediction.

These findings explain why blindly taking the default constructor could produce a larger download. [Exact constructors and loader](https://github.com/unum-cloud/UForm/blob/f4beec53743b44ffaad4ff754d65f6c2d347bbd9/swift/Encoders.swift).

The Swift SDK uses system Core ML/Core Graphics/Accelerate and a pinned `swift-transformers` fork. Its library product includes Tokenizers, Generation and Models targets, with Hub/config resources in the dependency graph. The package also declares ArgumentParser for CLI targets; that does not mean the CLI is automatically shipped with our app. No PyTorch or Python runtime is required by this Swift inference path. Exact linked binary size, dead stripping and transitive resource retention require a Release build. [UForm manifest](https://github.com/unum-cloud/UForm/blob/f4beec53743b44ffaad4ff754d65f6c2d347bbd9/Package.swift), [pinned dependency manifest](https://github.com/ashvardanian/swift-transformers/blob/89fb5d97e1df347f9f588f62fc538dcad6fdb16c/Package.swift).

## Effect on app behavior

Downloaded bytes, installed/compiled disk size and peak resident memory are different measurements. Loaded model tensors, Core ML execution allocations, tokenizer structures, input buffers, vectors and UI all consume resources beyond the file total. Quantized files can reduce disk costs; they do not establish the same RAM reduction. A 256-float embedding itself occupies 1,024 bytes: 10,000 one-image vectors are 10.24 MB before index metadata. Multiple crops increase vector count.

Publisher warm timing tables use preloaded models on an M4 iPad with iOS 18.2. Those conditions exclude keyboard cold opening, model compilation/download and our complete retrieval/UI path. They cannot establish an iPhone keyboard latency guarantee. [Publisher measurement conditions](https://github.com/unum-cloud/UForm/blob/f4beec53743b44ffaad4ff754d65f6c2d347bbd9/swift/README.md#choosing-target-device).

**Recommendation:** evaluate UForm as an optional paired-encoder module for the media path if that scope is approved. Provision pinned assets through the companion, cache compiled models, and precompute image vectors on the companion/Mac. Keep capture and initial lexical results independent of model loading. The keyboard should encode only a settled query if a text-only build passes cold/warm latency, peak memory, energy and repeated-activation tests on supported real phones. An iOS-compatible library does not establish keyboard-extension suitability. [Apple extension efficiency guidance](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionCreation.html).

No immediate installation is recommended. The benchmark should report Release binary/resources before and after integration, installed/compiled model storage, first-load time, p95 query encoding and full visible-result latency, peak resident memory, typing stalls and any extension terminations. If it fails those budgets, keep the model out of keyboard execution and bring that product tradeoff back for a decision. Core MVP approval does not silently approve an expanded image-understanding feature.
