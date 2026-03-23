"""
Custom Keras layers for ML/AttentionUNet.keras (saved with Keras 3.x).

Architecture matches the saved model graph: EncoderBlock (optional max-pool + skip),
AttentionGate (Oktay-style; gate g is coarser than skip x), DecoderBlock (upsample g,
concatenate with skip, two conv blocks).
"""

from __future__ import annotations

import tensorflow as tf
from tensorflow.keras import layers


class EncoderBlock(layers.Layer):
    """Two conv-BN-ReLU blocks, dropout, optional max-pool. If pooling: returns [pooled, pre_pool_skip]."""

    def __init__(self, filters: int, dropout_rate: float = 0.1, pooling: bool = True, **kwargs):
        super().__init__(**kwargs)
        self.filters = int(filters)
        self.dropout_rate = float(dropout_rate)
        self.pooling = bool(pooling)
        self.conv1 = layers.Conv2D(self.filters, 3, padding="same", use_bias=False)
        self.bn1 = layers.BatchNormalization()
        self.conv2 = layers.Conv2D(self.filters, 3, padding="same", use_bias=False)
        self.bn2 = layers.BatchNormalization()
        self.drop = layers.Dropout(self.dropout_rate)
        self.pool = layers.MaxPooling2D(2)

    def call(self, inputs, training=None):
        x = self.conv1(inputs)
        x = self.bn1(x, training=training)
        x = tf.nn.relu(x)
        x = self.conv2(x)
        x = self.bn2(x, training=training)
        x = tf.nn.relu(x)
        x = self.drop(x, training=training)
        if not self.pooling:
            return x
        skip = x
        p = self.pool(skip)
        return [p, skip]

    def get_config(self):
        cfg = super().get_config()
        cfg.update(
            {
                "filters": self.filters,
                "dropout_rate": self.dropout_rate,
                "pooling": self.pooling,
            }
        )
        return cfg


class AttentionGate(layers.Layer):
    """
    Attention gate: inputs [g, x] with g spatially coarser than x (e.g. 16x16 vs 32x32).
    """

    def __init__(self, filters: int, batchnorm: bool = True, **kwargs):
        super().__init__(**kwargs)
        self.filters = int(filters)
        self.batchnorm = bool(batchnorm)

    def build(self, input_shape):
        g_shape, x_shape = input_shape[0], input_shape[1]
        gh = g_shape[1] if g_shape[1] is not None else 1
        xh = x_shape[1] if x_shape[1] is not None else 2
        self._stride = max(1, int(xh // gh))
        self.theta = layers.Conv2D(
            self.filters,
            self._stride,
            strides=self._stride,
            padding="same",
            use_bias=not self.batchnorm,
        )
        self.phi = layers.Conv2D(self.filters, 1, padding="same", use_bias=not self.batchnorm)
        self.psi = layers.Conv2D(1, 1, padding="same", use_bias=True)
        if self.batchnorm:
            self.bn_theta = layers.BatchNormalization()
            self.bn_phi = layers.BatchNormalization()
        self.upsample_psi = layers.UpSampling2D(
            size=(self._stride, self._stride),
            interpolation="bilinear",
        )
        super().build(input_shape)

    def call(self, inputs, training=None):
        g, x = inputs
        if self.batchnorm:
            theta_x = self.bn_theta(self.theta(x), training=training)
            phi_g = self.bn_phi(self.phi(g), training=training)
        else:
            theta_x = self.theta(x)
            phi_g = self.phi(g)
        f = tf.nn.relu(theta_x + phi_g)
        psi = tf.nn.sigmoid(self.psi(f))
        psi_up = self.upsample_psi(psi)
        return x * psi_up

    def get_config(self):
        cfg = super().get_config()
        cfg.update({"filters": self.filters, "batchnorm": self.batchnorm})
        return cfg


class DecoderBlock(layers.Layer):
    """inputs [g, x]: upsample g x2, concat with x, two conv-BN-ReLU + dropout."""

    def __init__(self, filters: int, dropout_rate: float = 0.2, **kwargs):
        super().__init__(**kwargs)
        self.filters = int(filters)
        self.dropout_rate = float(dropout_rate)
        self.up = layers.UpSampling2D(2, interpolation="bilinear")
        self.conv1 = layers.Conv2D(self.filters, 3, padding="same", use_bias=False)
        self.bn1 = layers.BatchNormalization()
        self.conv2 = layers.Conv2D(self.filters, 3, padding="same", use_bias=False)
        self.bn2 = layers.BatchNormalization()
        self.drop = layers.Dropout(self.dropout_rate)

    def call(self, inputs, training=None):
        g, x = inputs
        u = self.up(g)
        c = tf.concat([u, x], axis=-1)
        h = self.conv1(c)
        h = self.bn1(h, training=training)
        h = tf.nn.relu(h)
        h = self.conv2(h)
        h = self.bn2(h, training=training)
        h = tf.nn.relu(h)
        h = self.drop(h, training=training)
        return h

    def get_config(self):
        cfg = super().get_config()
        cfg.update({"filters": self.filters, "dropout_rate": self.dropout_rate})
        return cfg
