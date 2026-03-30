# Attention U-Net checkpoint (`AttentionUNet.keras`)

## Symptom

`/ml-status` or `load_model()` fails with many layers like:

- `BatchNormalization` — *expected 4 variables, but received 0*
- `Conv2D` — *expected 1 variable, but received 2* (or the reverse)

TensorFlow / Keras version (e.g. 2.19.1) is usually **not** the root cause.

## Root cause: config vs weights mismatch inside the same `.keras` zip

A `.keras` file is a zip containing at least:

- `config.json` — graph (layer types, names, custom objects)
- `model.weights.h5` — variable tensors keyed by **layer paths**

Those two **must** come from the **same** `model.save(...)` call. If they are mixed from different exports, loading cannot assign weights.

### What we observed in this repo’s file

`config.json` describes blocks named like **`Encoder1`**, **`EncoderBlock`**, **`AttentionGate`**, **`DecoderBlock`** (see `ML/model_layers.py`).

`model.weights.h5` uses **different** paths, for example:

- `layers/encoder_block/.../conv1`, `conv2` only — **no** `bn1` / `bn2` tensors next to them
- `layers/attention_gate/W_g`, `W_x`, `batchnorm_layer`, `psi` — **not** the same names as `theta` / `phi` / `bn_theta` / `bn_phi` in `model_layers.py`
- `layers/decoder_block/encoder/conv1` — an **`encoder`** subpath that **DecoderBlock** in `model_layers.py` does **not** define

So the **weight file does not match** the **graph in config**. No TensorFlow pin or `TF_USE_LEGACY_KERAS` fix can repair that.

## Fix (required)

1. In the **same** training notebook / script that builds the model with **`ML/model_layers.py`** (or an identical copy of those classes), train or load weights, then save in one step:

   ```python
   model.save("AttentionUNet.keras")  # or keras.saving.save_model(model, "AttentionUNet.keras")
   ```

2. Replace `ML/AttentionUNet.keras` in the repo (or your deploy artifact) with that file.

3. Quick sanity check (optional): unzip the `.keras` and confirm weight group names align with your layer names (e.g. each `EncoderBlock` should have BN variables if the layer uses `BatchNormalization`).

4. Redeploy the API and confirm `GET /ml-status` returns `"ml_ready": true`.

Until the checkpoint is consistent, the API will keep using the **demo** inference path and the app will **not** show the real green segmentation overlay.

## Repo workaround: load `model.weights.h5` with a matching graph

If you cannot re-export the zip yet, the backend can still use the **weights** inside `model.weights.h5` by building a Functional model whose **nested layer names** match that HDF5 tree (`ML/attention_unet_builder.py`) and calling `load_weights(..., by_name=True)` on the extracted file.

**Keras 3 detail:** the temporary file used for extraction must use the suffix **`.h5`** only. A name ending in **`.weights.h5`** is treated as a different format and `load_weights(..., by_name=True)` raises *Invalid keyword arguments: {'by_name': True}*.
