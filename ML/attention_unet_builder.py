"""
Build Attention U-Net to match weights inside ML/AttentionUNet.keras (notebook export).

The zip's config.json does not match model.weights.h5 layout; this graph mirrors the HDF5
tree (e.g. encoder_block/conv1, decoder_block/encoder/drop, attention_gate/W_g).
"""

from __future__ import annotations

import tempfile
import zipfile
from pathlib import Path

import tensorflow as tf
from tensorflow.keras import layers


class EncoderBlockW(layers.Layer):
    """conv1 → relu → conv2 → relu → dropout → [pool + skip] or tensor (bottleneck)."""

    def __init__(self, filters: int, dropout_rate: float, pooling: bool = True, **kwargs):
        super().__init__(**kwargs)
        self.filters = int(filters)
        self.dropout_rate = float(dropout_rate)
        self.pooling = bool(pooling)
        self.conv1 = layers.Conv2D(self.filters, 3, padding="same", use_bias=True, name="conv1")
        self.conv2 = layers.Conv2D(self.filters, 3, padding="same", use_bias=True, name="conv2")
        self.drop = layers.Dropout(self.dropout_rate, name="drop")
        if self.pooling:
            self.pool = layers.MaxPooling2D(2, name="pool")

    def call(self, inputs, training=None):
        x = tf.nn.relu(self.conv1(inputs))
        x = tf.nn.relu(self.conv2(x))
        x = self.drop(x, training=training)
        if not self.pooling:
            return x
        skip = x
        return [self.pool(skip), skip]

    def get_config(self):
        c = super().get_config()
        c.update(
            {
                "filters": self.filters,
                "dropout_rate": self.dropout_rate,
                "pooling": self.pooling,
            }
        )
        return c


class AttentionGateW(layers.Layer):
    """Upsample g 2×, W_g / W_x, BN+ReLU, psi, sigmoid, multiply x."""

    def __init__(self, filters: int, **kwargs):
        super().__init__(**kwargs)
        self.filters = int(filters)
        self.W_g = layers.Conv2D(self.filters, 1, padding="same", use_bias=True, name="W_g")
        self.W_x = layers.Conv2D(self.filters, 1, padding="same", use_bias=True, name="W_x")
        self.batchnorm_layer = layers.BatchNormalization(name="batchnorm_layer")
        self.psi = layers.Conv2D(1, 1, padding="same", use_bias=True, name="psi")
        self._upsample = layers.UpSampling2D(2, interpolation="bilinear")

    def call(self, inputs, training=None):
        g, x = inputs
        g_up = self._upsample(g)
        g_phi = self.W_g(g_up)
        x_theta = self.W_x(x)
        f = tf.nn.relu(g_phi + x_theta)
        f = self.batchnorm_layer(f, training=training)
        psi = tf.nn.sigmoid(self.psi(f))
        return x * psi

    def get_config(self):
        c = super().get_config()
        c.update({"filters": self.filters})
        return c


class _DecoderEncoderInner(layers.Layer):
    """decoder_block/encoder/{conv1,conv2,drop}"""

    def __init__(self, filters: int, dropout_rate: float, **kwargs):
        super().__init__(**kwargs)
        self.filters = int(filters)
        self.dropout_rate = float(dropout_rate)
        self.conv1 = layers.Conv2D(self.filters, 3, padding="same", use_bias=True, name="conv1")
        self.conv2 = layers.Conv2D(self.filters, 3, padding="same", use_bias=True, name="conv2")
        self.drop = layers.Dropout(self.dropout_rate, name="drop")

    def call(self, x, training=None):
        x = tf.nn.relu(self.conv1(x))
        x = tf.nn.relu(self.conv2(x))
        return self.drop(x, training=training)

    def get_config(self):
        c = super().get_config()
        c.update({"filters": self.filters, "dropout_rate": self.dropout_rate})
        return c


class DecoderBlockW(layers.Layer):
    """Define `encoder` then `up` so trackable order matches typical Keras zip layout."""

    def __init__(self, filters: int, dropout_rate: float, **kwargs):
        super().__init__(**kwargs)
        self.filters = int(filters)
        self.dropout_rate = float(dropout_rate)
        self.encoder = _DecoderEncoderInner(filters, dropout_rate, name="encoder")
        self.up = layers.UpSampling2D(2, interpolation="bilinear", name="up")

    def call(self, inputs, training=None):
        g, x = inputs
        u = self.up(g)
        c = tf.concat([u, x], axis=-1)
        return self.encoder(c, training=training)

    def get_config(self):
        c = super().get_config()
        c.update({"filters": self.filters, "dropout_rate": self.dropout_rate})
        return c


def build_attention_unet_for_notebook_weights() -> tf.keras.Model:
    inp = layers.Input(shape=(256, 256, 3), name="input_layer")

    e1 = EncoderBlockW(16, 0.1, True, name="encoder_block")(inp)
    e2 = EncoderBlockW(32, 0.1, True, name="encoder_block_1")(e1[0])
    e3 = EncoderBlockW(64, 0.2, True, name="encoder_block_2")(e2[0])
    e4 = EncoderBlockW(128, 0.2, True, name="encoder_block_3")(e3[0])
    enc = EncoderBlockW(256, 0.3, False, name="encoder_block_4")(e4[0])

    a1 = AttentionGateW(128, name="attention_gate")([enc, e4[1]])
    d1 = DecoderBlockW(128, 0.2, name="decoder_block")([enc, a1])

    a2 = AttentionGateW(64, name="attention_gate_1")([d1, e3[1]])
    d2 = DecoderBlockW(64, 0.2, name="decoder_block_1")([d1, a2])

    a3 = AttentionGateW(32, name="attention_gate_2")([d2, e2[1]])
    d3 = DecoderBlockW(32, 0.1, name="decoder_block_2")([d2, a3])

    a4 = AttentionGateW(16, name="attention_gate_3")([d3, e1[1]])
    d4 = DecoderBlockW(16, 0.1, name="decoder_block_3")([d3, a4])

    out = layers.Conv2D(1, 1, activation="sigmoid", padding="same", use_bias=True, name="conv2d")(d4)
    return tf.keras.Model(inputs=inp, outputs=out, name="attention_unet_notebook")


def load_weights_from_keras_zip(model: tf.keras.Model, keras_zip_path: str | Path) -> None:
    path = Path(keras_zip_path)
    with zipfile.ZipFile(path, "r") as zf:
        data = zf.read("model.weights.h5")
    # Suffix must be `.h5` (not `.weights.h5`): Keras 3 treats `.weights.h5` as a format that rejects by_name=True.
    with tempfile.NamedTemporaryFile(suffix=".h5", delete=True) as tmp:
        tmp.write(data)
        tmp.flush()
        # Nested layers share sub-names (e.g. many `conv1`); by_name matches HDF5 paths.
        model.load_weights(tmp.name, by_name=True)


def build_and_load_from_notebook_keras(keras_zip_path: str | Path) -> tf.keras.Model:
    m = build_attention_unet_for_notebook_weights()
    load_weights_from_keras_zip(m, keras_zip_path)
    return m
