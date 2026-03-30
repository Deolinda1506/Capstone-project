"""Unit tests for backend inference helpers and predict_imt (mocked model)."""

from __future__ import annotations

import numpy as np
import pytest

import backend.inference as inf


class TestImtMmFromMask:
    def test_empty_mask_returns_nan(self):
        mask = np.zeros((32, 32), dtype=np.uint8)
        assert np.isnan(inf._imt_mm_from_mask(mask, spacing_mm_per_pixel=0.04))

    def test_single_wall_mask(self):
        """One thin horizontal line: min == max per column → zero thickness → IMT 0."""
        mask = np.zeros((32, 32), dtype=np.uint8)
        mask[16, :] = 1
        val = inf._imt_mm_from_mask(mask, spacing_mm_per_pixel=0.04)
        assert val == 0.0

    def test_spacing_scaling(self):
        """Same geometry; doubling mm/px doubles mean IMT."""
        mask = np.zeros((40, 40), dtype=np.uint8)
        mask[10:20, 15:25] = 1
        a = inf._imt_mm_from_mask(mask, spacing_mm_per_pixel=0.04)
        b = inf._imt_mm_from_mask(mask, spacing_mm_per_pixel=0.08)
        assert not np.isnan(a) and not np.isnan(b)
        assert abs(b / a - 2.0) < 1e-6


class TestStenosisPctNascet:
    def test_nascet_formula(self):
        # (1 - 5/10) * 100 = 50
        assert abs(inf._stenosis_pct_nascet(5.0, 10.0) - 50.0) < 1e-9

    def test_fully_patent(self):
        assert inf._stenosis_pct_nascet(10.0, 10.0) == 0.0

    def test_fully_occluded(self):
        assert inf._stenosis_pct_nascet(0.0, 10.0) == 100.0

    def test_invalid_distal_returns_nan(self):
        assert np.isnan(inf._stenosis_pct_nascet(5.0, 0.0))
        assert np.isnan(inf._stenosis_pct_nascet(5.0, -1.0))

    def test_clamped_to_0_100(self):
        """Negative NASCET % is clamped to 0; invalid negative diameters return NaN."""
        assert inf._stenosis_pct_nascet(20.0, 10.0) == 0.0
        assert np.isnan(inf._stenosis_pct_nascet(-1.0, 10.0))
        assert inf._stenosis_pct_nascet(0.0, 10.0) == 100.0


def _risk_level(imt_mm: float, patient_age: int | None) -> str:
    """Match predict_imt bucketing (threshold-inclusive high band)."""
    moderate_mm, high_mm = inf._get_imt_thresholds(patient_age)
    if imt_mm < moderate_mm:
        return "Low"
    if imt_mm < high_mm:
        return "Moderate"
    return "High"


class TestRiskLevel:
    def test_low_risk(self):
        assert _risk_level(0.5, None) == "Low"

    def test_moderate_risk(self):
        assert _risk_level(0.95, None) == "Moderate"

    def test_high_risk(self):
        assert _risk_level(1.5, None) == "High"

    def test_exact_high_threshold_is_high(self):
        """At IMT == high_mm, classify as High (upper threshold inclusive)."""
        assert _risk_level(1.2, None) == "High"


class TestValidationImtVsReference:
    def test_imt_within_acceptable_variation(self):
        """Band geometry: compare to nanmean(|outer-inner|)*spacing from the same mask."""
        mask = np.zeros((50, 50), dtype=np.uint8)
        mask[12:22, 10:40] = 1
        spacing = 0.04
        inner, outer = inf._get_interfaces_from_mask(mask)
        thickness = np.abs(outer - inner)
        ref = float(np.nanmean(thickness) * spacing)
        got = inf._imt_mm_from_mask(mask, spacing_mm_per_pixel=spacing)
        assert not np.isnan(got)
        assert abs(got - ref) < 1e-9


class TestModelInference:
    def test_predict_imt_uses_model(self, monkeypatch, minimal_png_bytes):
        """No real .keras load: stub predict() and assert structured output."""

        class FakeModel:
            def predict(self, batch, verbose=0):
                _ = batch
                out = np.zeros((1, 256, 256, 1), dtype=np.float32)
                # Wide enough band for plausibility QC (horizontal span + measurable thickness).
                out[0, 100:118, 100:150, 0] = 0.9
                return out

        monkeypatch.setattr(inf, "load_model", lambda: FakeModel())
        result = inf.predict_imt(
            minimal_png_bytes,
            spacing_mm_per_pixel=inf.DEFAULT_SPACING_MM_PER_PIXEL,
            return_segmentation_overlay=False,
            patient_age=None,
        )
        assert "imt_mm" in result
        assert result["risk_level"] in ("Low", "Moderate", "High", "Unknown")
        assert "inference_time_sec" in result
        assert result["stenosis_source"] in ("nascet", None)
        assert result.get("success") is True

    def test_predict_imt_fails_structural_check(self, monkeypatch, minimal_png_bytes):
        """Mask with < MIN_FOREGROUND_PIXELS foreground → success False and Unknown risk."""

        class FakeModel:
            def predict(self, batch, verbose=0):
                _ = batch
                out = np.zeros((1, 256, 256, 1), dtype=np.float32)
                out[0, 100:101, 100:101, 0] = 0.9  # 1 pixel only
                return out

        monkeypatch.setattr(inf, "load_model", lambda: FakeModel())
        result = inf.predict_imt(
            minimal_png_bytes,
            spacing_mm_per_pixel=inf.DEFAULT_SPACING_MM_PER_PIXEL,
            return_segmentation_overlay=False,
            patient_age=None,
        )
        assert result.get("success") is False
        assert result["imt_mm"] is None
        assert result["risk_level"] == "Unknown"
        assert "error" in result
        assert result["is_high_risk"] is False

    def test_predict_imt_fails_plausibility_bottom_speckle(self, monkeypatch, minimal_png_bytes):
        """Border-heavy mask should not return overlay or IMT."""

        class FakeModel:
            def predict(self, batch, verbose=0):
                _ = batch
                out = np.zeros((1, 256, 256, 1), dtype=np.float32)
                out[0, 248:256, 20:220, 0] = 0.95
                return out

        monkeypatch.setattr(inf, "load_model", lambda: FakeModel())
        result = inf.predict_imt(
            minimal_png_bytes,
            spacing_mm_per_pixel=inf.DEFAULT_SPACING_MM_PER_PIXEL,
            return_segmentation_overlay=False,
            patient_age=None,
        )
        assert result.get("success") is False
        assert result.get("has_ai_overlay") is False
        assert result.get("segmentation_overlay_base64") is None
        assert "quality" in (result.get("error") or "").lower()


class TestSegmentationPlausibility:
    def test_central_band_passes(self):
        m = np.zeros((256, 256), dtype=np.uint8)
        m[100:120, 96:160] = 1
        ok, reason = inf._segmentation_passes_plausibility(m, effective_spacing_mm=0.06)
        assert ok is True
        assert reason == ""

    def test_bottom_edge_band_fails(self):
        m = np.zeros((256, 256), dtype=np.uint8)
        m[248:256, 32:224] = 1
        ok, reason = inf._segmentation_passes_plausibility(m, effective_spacing_mm=0.06)
        assert ok is False
        assert reason in ("edge_concentrated", "mass_on_image_edge")
